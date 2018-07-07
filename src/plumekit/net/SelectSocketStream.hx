package plumekit.net;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import plumekit.stream.Sink;
import plumekit.stream.Source;
import sys.net.Socket;


class SelectSocketStream implements Source implements Sink {
    public var readTimeout(get, set):Float;
    public var writeTimeout(get, set):Float;

    var _readTimeout:Float = Math.POSITIVE_INFINITY;
    var _writeTimeout:Float = Math.POSITIVE_INFINITY;
    var socket:Socket;
    var dispatcher:SelectDispatcher;

    public function new(socket:Socket, ?dispatcher:SelectDispatcher) {
        this.socket = socket;
        this.dispatcher = dispatcher != null ? dispatcher : SelectDispatcher.instance();
    }

    function get_readTimeout():Float {
        return _readTimeout;
    }

    function set_readTimeout(value:Float):Float {
        return _readTimeout = value;
    }

    function get_writeTimeout():Float {
        return _writeTimeout;
    }

    function set_writeTimeout(value:Float):Float {
        return _writeTimeout = value;
    }

    public function close() {
        socket.close();
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Int {
        try {
            return socket.input.readBytes(bytes, position, length);
        } catch (exception:Any) {
            throw NetException.wrapHaxeException(exception);
        }
    }

    public function readReady():Task<Source> {
        return dispatcher.waitRead(socket, _readTimeout)
            .continueWith(function (task) {
                task.getResult();
                return TaskTools.fromResult((this:Source));
            });
    }

    public function flush() {
        socket.output.flush();
    }

    public function write(bytes:Bytes, position:Int, length:Int):Int {
        try {
            return socket.output.writeBytes(bytes, position, length);
        } catch (exception:Any) {
            throw NetException.wrapHaxeException(exception);
        }
    }

    public function writeReady():Task<Sink> {
        return dispatcher.waitWrite(socket, _writeTimeout)
            .continueWith(function (task) {
                task.getResult();
                return TaskTools.fromResult((this:Sink));
            });
    }
}
