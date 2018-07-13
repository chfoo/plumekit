package plumekit.stream;

import callnest.TaskTools;
import haxe.io.Bytes;
import haxe.ds.Option;
import callnest.Task;


class PipeTransfer {
    var source:Source;
    var sink:Sink;
    var chunkSize:Int;
    var buffer:Bytes;
    var bufferPosition:Int = 0;
    var bufferLength:Int = 0;

    public function new(source:Source, sink:Sink, chunkSize:Int = 8192) {
        this.source = source;
        this.sink = sink;
        this.chunkSize = chunkSize;
        buffer = Bytes.alloc(chunkSize);
    }

    public function transferAll():Task<Int> {
        return transferAllIteration(0);
    }

    function transferAllIteration(totalBytesRead:Int):Task<Int> {
        return transferChunk().continueWith(function (task) {
            switch (task.getResult()) {
                case Some(bytesRead):
                    return transferAllIteration(totalBytesRead + bytesRead);
                case None:
                    return TaskTools.fromResult(totalBytesRead);
            }
        });
    }

    public function transferChunk():Task<Option<Int>> {
        if (bufferLength > 0) {
            return sink.writeReady().continueWith(writeReadyCallback);
        }

        return source.readReady()
            .continueWith(readReadyCallback)
            .continueWith(bufferFilledCallback);
    }

    function readReadyCallback(task:Task<Source>):Task<Option<Int>> {
        task.getResult();

        switch (source.readInto(buffer, 0, buffer.length)) {
            case Some(bytesRead):
                bufferPosition = 0;
                bufferLength = bytesRead;
                return TaskTools.fromResult(Some(bytesRead));
            case None:
                return TaskTools.fromResult(None);
        }
    }

    function bufferFilledCallback(task:Task<Option<Int>>):Task<Option<Int>> {
        switch (task.getResult()) {
            case Some(bytesRead):
                return sink.writeReady().continueWith(writeReadyCallback);
            case None:
                return TaskTools.fromResult(None);
        }
    }

    function writeReadyCallback(task:Task<Sink>):Task<Option<Int>> {
        task.getResult();

        var bytesWritten = sink.write(buffer, bufferPosition, bufferLength);
        bufferPosition += bytesWritten;
        bufferLength -= bytesWritten;

        Debug.assert(bufferLength >= 0, bufferLength);

        return TaskTools.fromResult(Some(bytesWritten));
    }
}
