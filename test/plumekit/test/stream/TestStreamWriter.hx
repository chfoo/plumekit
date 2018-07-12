package plumekit.test.stream;

import callnest.TaskTools;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import plumekit.stream.OutputStream;
import plumekit.stream.StreamWriter;
import utest.Assert;


class TestStreamWriter {
    public function new() {
    }

    public function testWrite() {
        var bytesOutput = new BytesOutput();
        var bytesStream = new OutputStream(bytesOutput);
        var streamWriter = new StreamWriter(bytesStream);

        var count = 0;
        var expected = "";

        for (count in 0...10) {
            expected += "Hello world!\n";
        }

        var done, writeIteration, writeCallback;

        writeIteration = function () {
            var bytes = Bytes.ofString("Hello world!\n");

            return streamWriter.write(bytes).continueWith(writeCallback);
        }

        writeCallback = function (task) {
            var bytesWritten = task.getResult();
            Assert.equals(13, bytesWritten);

            count += 1;

            if (count < 10) {
                return writeIteration();
            } else {
                streamWriter.close();
                return TaskTools.fromResult(true);
            }
        }

        done = TaskTestTools.startAsync(function () {
            var result = bytesOutput.getBytes().toString();

            Assert.equals(expected, result);
        });

        writeIteration().onComplete(function (task) {
            done();
        }).handleException(exceptionHandler);
    }

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
