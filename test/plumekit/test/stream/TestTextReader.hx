package plumekit.test.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import plumekit.stream.ReadScanResult;
import plumekit.stream.TextReader;
import utest.Assert;


class TestTextReader {
    public function new() {
    }

    public function testReadAmount() {
        var bytes = Bytes.ofString("Hello world!");
        var bytesInput = new BytesInput(bytes);
        var inputStream = new InputStream(bytesInput);
        var textReader = new TextReader(inputStream);

        var resultBuffer = new StringBuf();
        var done = TaskTestTools.startAsync(function () {
            var resultText = resultBuffer.toString();

            Assert.equals("Hello world!", resultText);
        });

        var readIteration, readCallback;

        readIteration = function ():Task<Bool> {
            return textReader.read(5).continueWith(readCallback);
        }

        readCallback = function (task:Task<Option<String>>) {
            switch (task.getResult()) {
                case Some(text):
                    resultBuffer.add(text);
                    return readIteration();
                case None:
                    return TaskTools.fromResult(true);
            }
        };

        readIteration()
            .onComplete(function (task) {
                task.getResult();

                done();
            })
            .handleException(exceptionHandler);
    }

    public function testReadAll() {
        var bytes = Bytes.ofString("Hello world!");
        var bytesInput = new BytesInput(bytes);
        var inputStream = new InputStream(bytesInput);
        var textReader = new TextReader(inputStream);

        var resultText:String = null;
        var done = TaskTestTools.startAsync(function () {
            Assert.equals("Hello world!", resultText);
        });

        textReader.readAll()
            .onComplete(function (task) {
                resultText = task.getResult();
                done();
            })
            .handleException(exceptionHandler);
    }

    public function testReadLine() {
        var bytes = Bytes.ofString(
            "Cat\nDog\r\nBird\rFish\n" +
            "Cat\nDog\r\nBird\rFish\n"
        );
        var bytesInput = new BytesInput(bytes);
        var inputStream = new InputStream(bytesInput);
        var textReader = new TextReader(inputStream);

        var expectedLines = [
            "Cat", "Dog", "Bird", "Fish",
            "Cat\n", "Dog\r\n", "Bird\r", "Fish\n"
        ];
        var lines = [];
        var done = TaskTestTools.startAsync(function () {
            Assert.equals(8, lines.length);
            Assert.same(expectedLines, lines);
        });

        var readLineCallback;

        function readIteration():Task<Bool> {
            var keepEnd = lines.length >= 4;

            return textReader.readLine(keepEnd).continueWith(readLineCallback);
        };

        readLineCallback = function (task:Task<ReadScanResult<String>>) {
            switch (task.getResult()) {
                case ReadScanResult.Success(line):
                    lines.push(line);
                    return readIteration();

                case ReadScanResult.Incomplete(line):
                    return TaskTools.fromResult(true);

                case ReadScanResult.OverLimit(line):
                    return TaskTools.fromResult(false);
            }
        };

        readIteration()
            .onComplete(function (task) {
                task.getResult();
                done();
            })
            .handleException(exceptionHandler);
    }

    function testBufferFull() {
        var bytes = Bytes.ofString("Hello\r\nworld");
        var bytesInput = new BytesInput(bytes);
        var inputStream = new InputStream(bytesInput);
        var textReader = new TextReader(inputStream, 6, 2);

        var done = TaskTestTools.startAsync();

        textReader.readLine(true)
            .continueWith(function (task) {
                switch (task.getResult()) {
                    case ReadScanResult.OverLimit(line):
                        Assert.equals("Hello", line);
                    default:
                        Assert.fail();
                }

                return textReader.readLine(true);
            })
            .continueWith(function (task) {
                switch (task.getResult()) {
                    case ReadScanResult.Success(line):
                        Assert.equals("\r\n", line);
                    default:
                        Assert.fail();
                }

                return textReader.readLine(true);
            })
            .onComplete(function (task) {
                switch (task.getResult()) {
                    case ReadScanResult.Incomplete(line):
                        Assert.equals("world", line);
                    default:
                        Assert.fail();
                }

                done();
            })
            .handleException(exceptionHandler);
    }

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
