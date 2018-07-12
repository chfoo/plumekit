package plumekit.stream;

import callnest.Task;
import callnest.TaskDefaults;
import callnest.TaskSource;
import commonbox.ds.Deque;
import haxe.ds.Option;
import haxe.io.Bytes;


class MemoryStream implements Source implements Sink {
    public var readTimeout(get, set):Float;
    public var writeTimeout(get, set):Float;

    var _readTimeout:Float = Math.POSITIVE_INFINITY;
    var _writeTimeout:Float = Math.POSITIVE_INFINITY;

    var buffer:Deque<Int>;
    var maxBufferSize:Int;
    var readTaskSource:TaskSource<Source>;
    var writeTaskSource:TaskSource<Sink>;
    var isEOF = false;

    public function new(?maxBufferSize:Int) {
        this.maxBufferSize = maxBufferSize != null ? maxBufferSize : -1;
        buffer = new Deque(maxBufferSize);

        Debug.assert(this.maxBufferSize != 0);
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

    public function close():Void {
        isEOF = true;
    }

    public function flush():Void {
        // empty
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Option<Int> {
        var count = 0;

        while (count < length) {
            switch (buffer.shift()) {
                case Some(byte):
                    bytes.set(position + count, byte);
                    count += 1;
                case None:
                    break;
            }
        }

        if (isEOF && count == 0) {
            return None;
        }

        if (maxBufferSize < 0 || buffer.length < maxBufferSize) {
            triggerWriteTaskSource();
        }

        return Some(count);
    }

    public function readReady():Task<Source> {
        Debug.assert(readTaskSource == null || readTaskSource.task.isComplete);

        readTaskSource = TaskDefaults.newTaskSource();

        if (!buffer.isEmpty() || isEOF) {
            triggerReadTaskSource();
        }

        return readTaskSource.task;
    }

    function triggerReadTaskSource() {
        Debug.assert(readTaskSource != null);

        if (!readTaskSource.task.isComplete) {
            readTaskSource.setResult(this);
        }
    }

    public function write(bytes:Bytes, position:Int, length:Int):Int {
        if (isEOF) {
            throw new StreamException.EndOfFileException();
        }

        var count = 0;

        for (index in position...position + length) {
            if (maxBufferSize > 0 && buffer.length >= maxBufferSize) {
                break;
            }

            buffer.push(bytes.get(index));
            count += 1;
        }

        if (readTaskSource != null) {
            triggerReadTaskSource();
        }

        return count;
    }

    public function writeReady():Task<Sink> {
        Debug.assert(writeTaskSource == null || writeTaskSource.task.isComplete);

        writeTaskSource = TaskDefaults.newTaskSource();

        if (maxBufferSize < 0 || buffer.length < maxBufferSize || isEOF) {
            triggerWriteTaskSource();
        }

        return writeTaskSource.task;
    }

    function triggerWriteTaskSource() {
        Debug.assert(writeTaskSource != null);

        if (!writeTaskSource.task.isComplete) {
            writeTaskSource.setResult(this);
        }
    }
}
