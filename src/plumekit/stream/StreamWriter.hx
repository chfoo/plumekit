package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;


class StreamWriter implements Writer {
    var sink:Sink;
    var sourceBytes:Bytes;
    var position:Int;
    var bytesWritten:Int = 0;
    var length:Int;

    public function new(sink:Sink) {
        this.sink = sink;
    }

    public function close() {
        sink.close();
    }
    public function flush() {
        sink.flush();
    }

    public function write(bytes:Bytes, ?position:Int, ?length:Int):Task<Int> {
        this.position = position != null ? position : 0;
        this.length = length != null ? length : bytes.length - this.position;
        sourceBytes = bytes;
        bytesWritten = 0;

        return writeIteration();
    }

    function writeIteration():Task<Int> {
        return sink.writeReady().continueWith(writeReadyCallback);
    }

    function writeReadyCallback(task:Task<Sink>):Task<Int> {
        var index = position + bytesWritten;
        var remain = length - bytesWritten;

        if (remain == 0) {
             return TaskTools.fromResult(bytesWritten);
        }

        Debug.assert(index >= 0);
        Debug.assert(index < sourceBytes.length);
        Debug.assert(remain > 0);

        bytesWritten += sink.write(sourceBytes, index, remain);

        if (bytesWritten < length) {
            return writeIteration();
        } else {
            cleanUp();
            return TaskTools.fromResult(bytesWritten);
        }
    }

    function cleanUp() {
        sourceBytes = null;
    }
}
