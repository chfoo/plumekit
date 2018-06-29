package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import commonbox.ds.Deque;
import haxe.io.Bytes;


class BufferedReader implements Reader {
    var streamReader:StreamReader;
    var buffer:Deque<Int>;
    var chunkSize:Int;

    public function new(source:Source, maxBufferSize:Int = 16384, chunkSize:Int = 8192) {
        this.streamReader = new StreamReader(source);
        buffer = new Deque(maxBufferSize);
        this.chunkSize = chunkSize;
    }

    public function close() {
        streamReader.close();
    }

    public function readUntil(char:Int):Task<ReadResult<Bytes>> {
        return readUntilIteration(char, 0);
    }

    function readUntilIteration(char:Int, fromIndex:Int):Task<ReadResult<Bytes>> {
        switch (buffer.indexOf(char, fromIndex)) {
            case Some(index):
                return readUntilReturnBufferResult(index + 1);
            case None:
                fromIndex += buffer.length;

                return readUntilFillBuffer(char, fromIndex);
        }
    }

    function readUntilReturnBufferResult(length:Int):Task<ReadResult<Bytes>> {
         var bytes = Bytes.alloc(length);
        shiftBuffer(bytes, 0, length);
        return TaskTools.fromResult(ReadResult.Success(bytes));
    }

    function readUntilFillBuffer(char:Int, fromIndex:Int):Task<ReadResult<Bytes>> {
        return fillBuffer().continueWith(function (task:Task<Int>) {
            var bytesRead = task.getResult();

            if (bytesRead > 0) {
                return readUntilIteration(char, fromIndex);
            } else {
                var bytes = Bytes.alloc(buffer.length);
                shiftBuffer(bytes, 0, buffer.length);
                return TaskTools.fromResult(ReadResult.Incomplete(bytes));
            }
        });
    }

    public function read(?amount:Int):Task<ReadResult<Bytes>> {
        amount = amount != null ? amount : -1;

        if (amount >= 0) {
            return readAmount(amount);
        } else {
            return readAmountAll();
        }
    }

    function readAmount(amount:Int):Task<ReadResult<Bytes>> {
        var destBytes = Bytes.alloc(amount);
        var task = readInto(destBytes, 0, amount);

        return task.continueWith(function (task:Task<ReadIntoResult>) {
            switch (task.getResult()) {
                case ReadIntoResult.Success:
                    return TaskTools.fromResult(ReadResult.Success(destBytes));
                case ReadIntoResult.Incomplete(bytesRead):
                    var slice = destBytes.sub(0, bytesRead);
                    return TaskTools.fromResult(ReadResult.Incomplete(slice));
            }
        });
    }

    function readAmountAll():Task<ReadResult<Bytes>> {
        return readAll().continueWith(function (task:Task<Bytes>) {
            var bytes = task.getResult();
            return TaskTools.fromResult(ReadResult.Success(bytes));
        });
    }

    public function readOnce(?amount:Int):Task<Bytes> {
        amount = amount != null ? amount : chunkSize;

        if (!buffer.isEmpty()) {
            return readOnceFromBuffer(amount);
        } else {
            return streamReader.readOnce(amount);
        }
    }

    function readOnceFromBuffer(amount:Int):Task<Bytes> {
        amount = Std.int(Math.min(amount, buffer.length));

        var bytes = Bytes.alloc(amount);
        shiftBuffer(bytes, 0, amount);

        return TaskTools.fromResult(bytes);
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Task<ReadIntoResult> {
        var shiftedCount = shiftBuffer(bytes, position, length);

        function callback(task) {
            switch (task.getResult()) {
                case ReadIntoResult.Success:
                    return TaskTools.fromResult(ReadIntoResult.Success);
                case ReadIntoResult.Incomplete(bytesRead):
                    return TaskTools.fromResult(
                        ReadIntoResult.Incomplete(shiftedCount + bytesRead));
            }
        }

        return streamReader.readInto(
            bytes, position + shiftedCount, length - shiftedCount)
            .continueWith(callback);
    }

    public function readIntoOnce(bytes:Bytes, position:Int, length:Int):Task<Int> {
        if (!buffer.isEmpty()) {
            return TaskTools.fromResult(shiftBuffer(bytes, position, length));
        } else {
            return streamReader.readIntoOnce(bytes, position, length);
        }
    }

    public function readAll():Task<Bytes> {
        if (buffer.isEmpty()) {
            return streamReader.readAll();
        } else {
            return streamReader.readAll().continueWith(readAllCallback);
        }
    }

    function readAllCallback(task:Task<Bytes>):Task<Bytes> {
        var bufferLength = buffer.length;
        var bytes = task.getResult();
        var newDest = Bytes.alloc(bufferLength + bytes.length);

        shiftBuffer(newDest, 0, bufferLength);
        newDest.blit(bufferLength, bytes, 0, bytes.length);

        return TaskTools.fromResult(newDest);
    }

    function shiftBuffer(dest:Bytes, position:Int, length:Int):Int {
        var count = 0;

        for (index in position...position + length) {
            switch (buffer.shift()) {
                case Some(byte):
                    dest.set(index, byte);
                    count += 1;
                case None:
                    break;
            }
        }

        return count;
    }

    function fillBuffer():Task<Int> {
        var task = streamReader.readOnce(chunkSize);

        return task.continueWith(function (task:Task<Bytes>) {
            var bytes = task.getResult();

            for (index in 0...bytes.length) {
                buffer.push(bytes.get(index));
            }

            return TaskTools.fromResult(bytes.length);
        });
    }
}
