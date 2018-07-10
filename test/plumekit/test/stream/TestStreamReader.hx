package plumekit.test.stream;

import callnest.TaskTools;
import callnest.Task;
import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import plumekit.stream.ReadResult;
import plumekit.stream.ReadIntoResult;
import plumekit.stream.StreamReader;
import utest.Assert;


class TestStreamReader {
    public function new() {
    }

    function getSampleText():String {
        var buffer = new StringBuf();

        for (index in 0...10) {
            buffer.add("Hello world!\n");
        }

        return buffer.toString();
    }

    function getStreamReader() {
        var bytes = Bytes.ofString(getSampleText());
        var bytesInput = new BytesInput(bytes);
        var inputStream = new InputStream(bytesInput);
        var streamReader = new StreamReader(inputStream);

        return streamReader;
    }

    public function testReadInto() {
        var streamReader = getStreamReader();
        var resultBytes = Bytes.alloc(10);
        var done = Assert.createAsync();

        streamReader.readInto(resultBytes, 0, 5).onComplete(function (task) {
            switch (task.getResult()) {
                case ReadIntoResult.Success:
                    Assert.equals("Hello", resultBytes.sub(0,5).toString());
                case ReadIntoResult.Incomplete(bytesRead):
                    Assert.fail('bytesRead = $bytesRead');
            }

            done();
        }).handleException(exceptionHandler);
    }

    public function testReadIntoOnce() {
        var streamReader = getStreamReader();

        var resultBytes = Bytes.alloc(10);
        var done = Assert.createAsync();

        streamReader.readIntoOnce(resultBytes, 0, 5).onComplete(function (task) {
            var bytesRead = task.getResult();
            Assert.same(Some(5), bytesRead);
            Assert.equals("H".code, resultBytes.get(0));

            done();

        }).handleException(exceptionHandler);
    }

    public function testReadAll() {
        var streamReader = getStreamReader();
        var text = getSampleText();

        var done = Assert.createAsync();

        streamReader.readAll().onComplete(function (task) {
            var resultBytes = task.getResult();

            Assert.equals(text, resultBytes.toString());

            done();
        }).handleException(exceptionHandler);
    }

    public function testRead() {
        var streamReader = getStreamReader();
        var text = getSampleText();

        var resultBuf = new BytesBuffer();
        var done = Assert.createAsync(function () {
            var resultBytes = resultBuf.getBytes();

            Assert.equals(text, resultBytes.toString());
        });

        var readCallback;

        function readIteration():Task<Bool> {
            return streamReader.read(10).continueWith(readCallback);
        }

        readCallback = function (task:Task<ReadResult<Bytes>>):Task<Bool> {
            var readResult = task.getResult();

            switch (readResult) {
                case ReadResult.Success(bytes):
                    resultBuf.add(bytes);
                    return readIteration();
                case ReadResult.Incomplete(bytes):
                    resultBuf.add(bytes);
                    streamReader.close();
                    return TaskTools.fromResult(true);
            }
        }

        readIteration().onComplete(function (task) {
            task.getResult();

            done();
        }).handleException(exceptionHandler);
    }

    public function testReadOnce() {
        var streamReader = getStreamReader();

        var done = Assert.createAsync();

        streamReader.readOnce(5).onComplete(function (task) {
            switch (task.getResult()) {
                case Some(bytes):
                    Assert.equals("H".code, bytes.get(0));
                case None:
                    Assert.fail();
            }
            done();
        }).handleException(exceptionHandler);
    }

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
