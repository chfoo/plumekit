package plumekit.net;

import commonbox.Exception.FullException;
import callnest.Task;
import callnest.TaskDefaults;
import callnest.TaskSource;
import callnest.TaskTools;
import commonbox.ds.Deque;
import haxe.ds.Option;
import haxe.io.Bytes;
import js.Browser;
import js.html.ArrayBuffer;
import js.html.BinaryType;
import js.html.CloseEvent;
import js.html.DataView;
import js.html.MessageEvent;
import js.html.Uint8Array;
import js.html.WebSocket;
import plumekit.stream.Sink;
import plumekit.stream.Source;
import plumekit.stream.StreamException.EndOfFileException;

using plumekit.net.WebSocketTools;


class WebSocketClientStream implements Source implements Sink {
    public var readTimeout(get, set):Float;
    public var writeTimeout(get, set):Float;

    var webSocket:Option<WebSocket> = None;
    var source:WebSocketSource;
    var sink:WebSocketSink;

    public function new(inputBufferSize:Int = 65536, outputBufferSize:Int = 8192) {
        source = new WebSocketSource(inputBufferSize);
        sink = new WebSocketSink(outputBufferSize);
    }

    public function attach(webSocket:WebSocket) {
        this.webSocket = Some(webSocket);
        webSocket.binaryType = BinaryType.ARRAYBUFFER;
        webSocket.onclose = closeCallback;

        source.attach(webSocket);
        sink.attach(webSocket);
    }

    function get_readTimeout():Float {
        return source.readTimeout;
    }

    function set_readTimeout(value:Float):Float {
        return source.readTimeout = value;
    }

    function get_writeTimeout():Float {
        return sink.writeTimeout;
    }

    function set_writeTimeout(value:Float):Float {
        return sink.writeTimeout = value;
    }

    public function close() {
        switch webSocket {
            case Some(webSocket): webSocket.close();
            case None: // pass
        }
    }

    public function flush() {
        sink.flush();
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Option<Int> {
        return source.readInto(bytes, position, length);
    }
    public function readReady():Task<Source> {
        return source.readReady();
    }

    public function write(bytes:Bytes, position:Int, length:Int):Int {
        return sink.write(bytes, position, length);
    }
    public function writeReady():Task<Sink> {
        return sink.writeReady();
    }

    function closeCallback(event:CloseEvent) {
        source.close();
        sink.close();
    }
}


private class WebSocketSource implements Source {
    public var readTimeout(get, set):Float;

    var webSocket:Option<WebSocket> = None;
    var _readTimeout:Float = Math.POSITIVE_INFINITY;
    var inputBuffer:Deque<Int>;
    var readTaskSource:Option<TaskSource<Source>> = None;
    var bufferFull = false;

    public function new(bufferSize:Int) {
        inputBuffer = new Deque(bufferSize);
    }

    public function attach(webSocket:WebSocket) {
        this.webSocket = Some(webSocket);
        webSocket.onmessage = messageCallback;
    }

    function get_readTimeout():Float {
        return _readTimeout;
    }

    function set_readTimeout(value:Float):Float {
        return _readTimeout = value;
    }

    public function close() {
        switch webSocket {
            case Some(webSocket): webSocket.close();
            case None: // pass
        }

        notifyReadReady();
    }

    function messageCallback(event:MessageEvent) {
        var arrayBuffer:ArrayBuffer = event.data;
        var arrayView = new Uint8Array(arrayBuffer);

        try {
            for (index in 0...arrayView.length) {
                inputBuffer.push(arrayView[index]);
            }
        } catch (exception:FullException) {
            bufferFull = true;
        }

        notifyReadReady();
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Option<Int> {
        if (inputBuffer.isEmpty() && isClosed()) {
            return None;
        }

        var count = 0;

        for (index in 0...length) {
            switch inputBuffer.shift() {
                case Some(byte):
                    bytes.set(position + index, byte);
                    count += 1;
                case None:
                    break;
            }
        }

        return Some(count);
    }

    public function readReady():Task<Source> {
        if (!inputBuffer.isEmpty() || isClosed()) {
            return TaskTools.fromResult((this:Source));
        }

        Debug.assert(readTaskSource == None);
        var taskSource = TaskDefaults.newTaskSource();
        readTaskSource = Some(taskSource);

        return taskSource.task;
    }

    function notifyReadReady() {
        switch readTaskSource {
            case Some(taskSource):
                readTaskSource = None;

                if (bufferFull) {
                    taskSource.setException(new NetException("Read buffer full."));
                } else {
                    taskSource.setResult((this:Source));
                }
            case None:
                // pass
        }
    }

    function isClosed():Bool {
        switch webSocket {
            case Some(webSocket): return webSocket.isClosed();
            case None: return false;
        }
    }
}

private class WebSocketSink implements Sink {
    public var writeTimeout(get, set):Float;

    var webSocket:Option<WebSocket>;
    var _writeTimeout:Float = Math.POSITIVE_INFINITY;
    var bufferSize:Int;
    var writeTaskSource:Option<TaskSource<Sink>> = None;
    var checkBufferTimerID:Option<Int> = None;
    var checkBufferInterval:Int = 10;

    public function new(bufferSize:Int) {
        this.bufferSize = bufferSize;
    }

    public function attach(webSocket:WebSocket) {
        this.webSocket = Some(webSocket);
    }

    function get_writeTimeout():Float {
        return _writeTimeout;
    }

    function set_writeTimeout(value:Float):Float {
        return _writeTimeout = value;
    }

    public function close() {
        switch webSocket {
            case Some(webSocket): webSocket.close();
            case None: // pass
        }

        cancelCheckBufferTimer();
        notifyWriteReady();
    }

    public function flush():Void {
        // no op
    }

    public function write(bytes:Bytes, position:Int, length:Int):Int {
        if (isClosed()) {
            throw new EndOfFileException("WebSocket closed");
        }

        var webSocket_;

        switch webSocket {
            case Some(value): webSocket_ = value;
            case None: throw "Web socket not initialized";
        }

        var available = Std.int(Math.max(0, bufferSize - webSocket_.bufferedAmount));
        var amount = Std.int(Math.min(length, available));
        var arrayView = new DataView(bytes.getData(), position, amount);
        webSocket_.send(arrayView);

        return amount;
    }

    public function writeReady():Task<Sink> {
        var webSocket_;
        switch webSocket {
            case Some(value): webSocket_ = value;
            case None: throw "Web socket not initialized";
        }

        if (webSocket_.isClosed() || webSocket_.bufferedAmount < bufferSize) {
            return TaskTools.fromResult((this:Sink));
        }

        Debug.assert(writeTaskSource == None);
        var taskSource = TaskDefaults.newTaskSource();
        writeTaskSource = Some(taskSource);
        scheduleCheckBuffer();

        return taskSource.task;
    }

    function notifyWriteReady() {
        switch writeTaskSource {
            case Some(taskSource):
                writeTaskSource = None;
                taskSource.setResult(this);
            case None:
                // pass
        }
    }

    function scheduleCheckBuffer(incrementInterval:Bool = false) {
        if (incrementInterval) {
            checkBufferInterval += 10;
        } else {
            checkBufferInterval = 10;
        }

        Debug.assert(checkBufferTimerID == None);
        checkBufferTimerID = Some(
            Browser.window.setTimeout(checkBufferCallback, checkBufferInterval)
        );
    }

    function checkBufferCallback() {
        checkBufferTimerID = None;

        var webSocket_;

        switch webSocket {
            case Some(value): webSocket_ = value;
            case None: throw "Web socket not initialized";
        }

        if (webSocket_.bufferedAmount < bufferSize) {
            notifyWriteReady();
        } else {
            scheduleCheckBuffer(true);
        }
    }

    function cancelCheckBufferTimer() {
        switch checkBufferTimerID {
            case Some(id):
                Browser.window.clearTimeout(id);
                checkBufferTimerID = None;
            case None:
                // pass
        }
    }

    function isClosed():Bool {
        switch webSocket {
            case Some(webSocket): return webSocket.isClosed();
            case None: return false;
        }
    }
}
