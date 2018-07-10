package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;


class StreamReader implements Reader {
    var source:Source;

    public function new(source:Source) {
        this.source = source;
    }

    public function close() {
        source.close();
    }

    public function read(amount:Int):Task<ReadResult<Bytes>> {
        if (amount >= 0) {
            return readByAmount(amount);
        } else {
            return TaskTools.fromResult(ReadResult.Success(Bytes.alloc(0)));
        }
    }

    function readByAmount(amount:Int):Task<ReadResult<Bytes>> {
        var destBytes = Bytes.alloc(amount);

        return readInto(destBytes, 0, amount).continueWith(function (task) {
            switch (task.getResult()) {
                case ReadIntoResult.Success:
                    return TaskTools.fromResult(ReadResult.Success(destBytes));
                case ReadIntoResult.Incomplete(bytesRead):
                    var slice = destBytes.sub(0, bytesRead);
                    return TaskTools.fromResult(ReadResult.Incomplete(slice));
            }
        });
    }

    public function readOnce(?amount:Int):Task<Option<Bytes>> {
        amount = amount != null ? amount : 8192;
        var bytes = Bytes.alloc(amount);

        return readIntoOnce(bytes, 0, amount).continueWith(function (task) {
            switch (task.getResult()) {
                case Some(bytesRead):
                    return TaskTools.fromResult(Some(bytes.sub(0, bytesRead)));
                case None:
                    return TaskTools.fromResult(None);
            }
        });
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Task<ReadIntoResult> {
        var impl = new ReadIntoImpl(source);
        return impl.readInto(bytes, position, length);
    }

    public function readIntoOnce(bytes:Bytes, position:Int, length:Int):Task<Option<Int>> {
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

    public function new(source:Source) {
        this.source = source;
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Task<ReadIntoResult> {
        this.destBytes = bytes;
        this.position = position;
        this.length = length;
        bytesRead = 0;

        if (length > 0) {
            return readIteration();
        } else {
            return TaskTools.fromResult(ReadIntoResult.Success);
        }
    }

    public function readIntoOnce(bytes:Bytes, position:Int, length:Int):Task<Option<Int>> {
        this.destBytes = bytes;
        this.position = position;
        this.length = length;
        bytesRead = 0;

        return source.readReady().continueWith(readOnceReadyCallback);
    }

    function readOnceReadyCallback(task:Task<Source>):Task<Option<Int>> {
        return TaskTools.fromResult(
            source.readInto(destBytes, position, length));
    }

    function readIteration():Task<ReadIntoResult> {
        return source.readReady().continueWith(readReadyCallback);
    }

    function readReadyCallback(task:Task<Source>):Task<ReadIntoResult> {
        var index = position + bytesRead;
        var remain = length - bytesRead;

        Debug.assert(index >= 0);
        Debug.assert(index < destBytes.length);
        Debug.assert(remain > 0);

        switch (source.readInto(destBytes, index, remain)) {
            case Some(resultBytesRead):
                bytesRead += resultBytesRead;
            case None:
                return TaskTools.fromResult(
                    ReadIntoResult.Incomplete(bytesRead));
        }

        remain = length - bytesRead;

        if (remain > 0) {
            return readIteration();
        } else {
            return TaskTools.fromResult(ReadIntoResult.Success);
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
        switch (source.readInto(chunkBuffer, 0, chunkBuffer.length)) {
            case Some(iterationBytesRead):
                bytesBuffer.addBytes(chunkBuffer, 0, iterationBytesRead);
            case None:
                return TaskTools.fromResult(bytesBuffer.getBytes());
        }

        return readIteration();
    }
}
