package plumekit.test.stream;

import callnest.Task;
import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.BufferedReader;
import plumekit.stream.InputStream;
import plumekit.stream.ReadIntoResult;
import plumekit.stream.ReadResult;
import plumekit.stream.ReadScanResult;
import utest.Assert;


class TestBufferedReader {
    public function new() {
    }

    public function testReadUntil() {
        var bytes = Bytes.ofString("hello\nworld!");
        var input = new BytesInput(bytes);
        var stream = new InputStream(input);
        var reader = new BufferedReader(stream, 16384, 2);

        var done = TaskTestTools.startAsync();

        function callback(task:Task<ReadScanResult<Bytes>>) {
            var result = task.getResult();

            switch (result) {
                case ReadScanResult.Success(bytes):
                    Assert.equals("hello\n", bytes.toString());
                case ReadScanResult.Incomplete(bytes):
                    Assert.equals("world!", bytes.toString());
                    done();
                case ReadScanResult.OverLimit(bytes):
                    Assert.fail();
            }
        }

        reader.readUntil("\n".code)
            .continueWith(function (task) {
                callback(task);
                return reader.readUntil("\n".code);
            })
            .onComplete(callback)
            .handleException(exceptionHandler);
    }

    function readUntilCallbackHelper(task:Task<ReadScanResult<Bytes>>)
            :Task<ReadScanResult<Bytes>> {
        var result = task.getResult();

        switch (result) {
            case ReadScanResult.Success(bytes):
                Assert.equals("0", bytes.toString());
            default:
                Assert.fail();
        }

        return task;
    }

    public function testReadAll() {
        var reader = getReader();
        var done = TaskTestTools.startAsync();

        reader.readUntil("0".code)
            .continueWith(readUntilCallbackHelper) // => 0 [123|456789]
            .continueWith(function (task) {
                return reader.readAll();
            })
            .onComplete(function (task:Task<Bytes>) {
                var bytes = task.getResult();
                Assert.equals("123456789", bytes.toString());

                done();
            })
            .handleException(exceptionHandler);
    }

    public function testRead() {
        var reader = getReader();
        var done = TaskTestTools.startAsync();

        reader.readUntil("0".code)
            .continueWith(readUntilCallbackHelper) // => 0 [123|456789]
            .continueWith(function (task) {
                return reader.read(5);
            }) // => 12345 [6789]
            .continueWith(function (task:Task<ReadResult<Bytes>>) {
                switch (task.getResult()) {
                    case ReadResult.Success(bytes):
                        Assert.equals("12345", bytes.toString());
                    default:
                        Assert.fail();
                }

                return reader.read(1234);
            })
            .onComplete(function (task:Task<ReadResult<Bytes>>) {
                switch (task.getResult()) {
                    case ReadResult.Incomplete(bytes):
                        Assert.equals("6789", bytes.toString());
                    default:
                        Assert.fail();
                }

                done();
            })
            .handleException(exceptionHandler);
    }

    function testReadOnce() {
        var reader = getReader();
        var done = TaskTestTools.startAsync();

        reader.readUntil("0".code)
            .continueWith(readUntilCallbackHelper) // => 0 [123|456789]
            .continueWith(function (task) {
                return reader.readOnce(5);
            }) // => 123 [456789]
            .onComplete(function (task:Task<Option<Bytes>>) {
                switch (task.getResult()) {
                    case Some(bytes):
                        Assert.equals("123", bytes.toString());
                    case None:
                        Assert.fail();
                }

                done();
            })
            .handleException(exceptionHandler);
    }

    function testReadInto() {
        var reader = getReader();
        var done = TaskTestTools.startAsync();
        var bytes = Bytes.alloc(9);

        reader.readUntil("0".code)
            .continueWith(readUntilCallbackHelper) // => 0 [123|456789]
            .continueWith(function (task) {
                task.getResult();
                return reader.readInto(bytes, 0, 5);
            }) // => 12345 [6789]
            .continueWith(function (task) {
                switch (task.getResult()) {
                    case ReadIntoResult.Success:
                    case ReadIntoResult.Incomplete(bytesRead):
                        Assert.fail('bytesRead = $bytesRead');
                }
                return reader.readInto(bytes, 5, 4);
            }) // => 6789
            .onComplete(function (task:Task<ReadIntoResult>) {
                task.getResult();
                Assert.equals("123456789", bytes.toString());

                done();
            })
            .handleException(exceptionHandler);
    }

    function testReadIntoOnce() {
        var reader = getReader();
        var done = TaskTestTools.startAsync();
        var bytes = Bytes.alloc(9);

        reader.readUntil("0".code)
            .continueWith(readUntilCallbackHelper) // => 0 [123|456789]
            .continueWith(function (task) {
                task.getResult();
                return reader.readIntoOnce(bytes, 0, 5);
            }) // => 123 [456789]
            .continueWith(function (task) {
                var bytesRead = task.getResult();
                Assert.same(Some(3), bytesRead);
                return reader.readIntoOnce(bytes, 3, 6);
            }) // => 456789 []
            .onComplete(function (task:Task<Option<Int>>) {
                task.getResult();
                Assert.equals("123456789", bytes.toString());

                done();
            })
            .handleException(exceptionHandler);
    }

    function testBufferFull() {
        var bytes = Bytes.ofString("hello world!");
        var input = new BytesInput(bytes);
        var stream = new InputStream(input);
        var reader = new BufferedReader(stream, 10, 2);

        var done = TaskTestTools.startAsync();

        function callback(task:Task<ReadScanResult<Bytes>>) {
            switch (task.getResult()) {
                case ReadScanResult.OverLimit(bytes):
                    Assert.equals(10, bytes.length);
                default:
                    Assert.fail();
            }
            done();
        }

        reader.readUntil("\n".code)
            .onComplete(callback)
            .handleException(exceptionHandler);
    }

    function getReader() {
        var bytes = Bytes.ofString("0123456789");
        var input = new BytesInput(bytes);
        var stream = new InputStream(input);
        var reader = new BufferedReader(stream, 16384, 4);

        return reader;
    }

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
