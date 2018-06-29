package plumekit.test.stream;

import haxe.io.BytesOutput;
import plumekit.stream.OutputStream;
import plumekit.stream.TextWriter;
import utest.Assert;


class TestTextWriter {
    public function new() {
    }

    public function testWrite() {
        var bytesOutput = new BytesOutput();
        var outputStream = new OutputStream(bytesOutput);
        var textWriter = new TextWriter(outputStream);

        var done = Assert.createAsync(function () {
            var bytes = bytesOutput.getBytes();
            Assert.equals(
                "F09F92BE48656C6C6F20776F726C6421",
                bytes.toHex().toUpperCase()
            );
        });

        textWriter.write("💾")
            .continueWith(function (task) {
                task.getResult();
                return textWriter.write("Hello world!");
            })
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
