package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Eof;


class StreamReader implements Reader {
    var source:Source;

    public function new(source:Source) {
        this.source = source;
    }

    public function close() {
        source.close();
    }

    public function read(?amount:Int):Task<ReadResult> {
        amount = amount != null ? amount : -1;

        if (amount >= 0) {
            return readByAmount(amount);
        } else {
            return readAll().continueWith(function (task) {
                return TaskTools.fromResult(ReadResult.Data(task.getResult()));
            });
        }
    }

    function readByAmount(amount:Int):Task<ReadResult> {
        var destBytes = Bytes.alloc(amount);

        return readInto(destBytes, 0, amount).continueWith(function (task) {
            var bytesRead = task.getResult();

            if (bytesRead == amount) {
                return TaskTools.fromResult(ReadResult.Data(destBytes));
            } else {
                var slice = destBytes.sub(0, bytesRead);
                return TaskTools.fromResult(ReadResult.Incomplete(slice));
            }
        });
    }

    public function readOnce(?amount:Int):Task<Bytes> {
        amount = amount != null ? amount : 8192;
        var bytes = Bytes.alloc(amount);

        return readIntoOnce(bytes, 0, amount).continueWith(function (task) {
            var bytesRead = task.getResult();
            return TaskTools.fromResult(bytes.sub(0, bytesRead));
        });
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Task<Int> {
        var impl = new ReadIntoImpl(source);
        return impl.readInto(bytes, position, length);
    }

    public function readIntoOnce(bytes:Bytes, position:Int, length:Int):Task<Int> {
        var impl = new ReadIntoImpl(source);
        return impl.readIntoOnce(bytes, position, length);
    }

    public function readAll():Task<Bytes> {
        var impl = new ReadAllImpl(source);
        return impl.readAll();
    }
}


private class ReadIntoImpl {
    var source:Source;
    var destBytes:Bytes;
    var position:Int;
    var length:Int;
    var bytesRead:Int = 0;
    var once:Bool = false;

    public function new(source:Source) {
        this.source = source;
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Task<Int> {
        this.destBytes = bytes;
        this.position = position;
        this.length = length;
        bytesRead = 0;

        if (length > 0) {
            return readIteration();
        } else {
            return TaskTools.fromResult(0);
        }
    }

    public function readIntoOnce(bytes:Bytes, position:Int, length:Int):Task<Int> {
        once = true;
        return readInto(bytes, position, length);
    }

    function readIteration():Task<Int> {
        return source.readReady().continueWith(readReadyCallback);
    }

    function readReadyCallback(task:Task<Source>):Task<Int> {
        var index = position + bytesRead;
        var remain = length - bytesRead;

        Debug.assert(index >= 0);
        Debug.assert(index < destBytes.length);
        Debug.assert(remain > 0);

        try {
            bytesRead += source.readInto(destBytes, index, remain);
        } catch (exception:Eof) {
            return TaskTools.fromResult(bytesRead);
        }

        remain = length - bytesRead;

        if (remain > 0 && !once) {
            return readIteration();
        } else {
            return TaskTools.fromResult(bytesRead);
        }
    }
}


private class ReadAllImpl {
    var source:Source;
    var bytesBuffer:BytesBuffer;
    var chunkBuffer:Bytes;

    public function new(source:Source, bufferSize:Int = 8096) {
        this.source = source;
        bytesBuffer = new BytesBuffer();
        chunkBuffer = Bytes.alloc(bufferSize);
    }

    public function readAll():Task<Bytes> {
        return readIteration();
    }

    function readIteration():Task<Bytes> {
        return source.readReady().continueWith(readReadyCallback);
    }

    function readReadyCallback(task:Task<Source>):Task<Bytes> {
        var iterationBytesRead;

        try {
            iterationBytesRead = source.readInto(chunkBuffer, 0, chunkBuffer.length);
        } catch (exception:Eof) {
            return TaskTools.fromResult(bytesBuffer.getBytes());
        }

        bytesBuffer.addBytes(chunkBuffer, 0, iterationBytesRead);

        return readIteration();
    }
}
