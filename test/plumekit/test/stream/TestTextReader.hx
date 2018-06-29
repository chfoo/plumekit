package plumekit.test.stream;

import haxe.CallStack;
import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import plumekit.stream.ReadResult;
import plumekit.stream.TextReader;
import utest.Assert;


class TestTextReader {
    public function new() {
    }

    public function testRead() {
        var bytes = Bytes.ofString("Hello world!");
        var bytesInput = new BytesInput(bytes);
        var inputStream = new InputStream(bytesInput);
        var textReader = new TextReader(inputStream);

        var resultBuffer = new StringBuf();
        var done = Assert.createAsync(function () {
            var resultText = resultBuffer.toString();

            Assert.equals("Hello world!", resultText);
        });

        textReader.read(5)
            .continueWith(function (task) {
                resultBuffer.add(task.getResult());

                return textReader.read();
            })
            .onComplete(function (task) {
                resultBuffer.add(task.getResult());

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
        var done = Assert.createAsync(function () {
            Assert.equals(8, lines.length);
            Assert.same(expectedLines, lines);
        });

        var readLineCallback;

        function readIteration():Task<Bool> {
            var keepEnd = lines.length >= 4;

            return textReader.readLine(keepEnd).continueWith(readLineCallback);
        };

        readLineCallback = function (task:Task<ReadResult<String>>) {
            switch (task.getResult()) {
                case ReadResult.Success(line):
                    lines.push(line);
                    return readIteration();

                case ReadResult.Incomplete(line):
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

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
