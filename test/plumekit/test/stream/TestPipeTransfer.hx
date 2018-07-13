package plumekit.test.stream;

import plumekit.stream.PipeTransfer;
import plumekit.stream.OutputStream;
import haxe.io.BytesOutput;
import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import utest.Assert;


class TestPipeTransfer {
    public function new() {
    }

    public function testBytesInput() {
        var bytes = Bytes.ofString("Hello world!");
        var bytesInput = new BytesInput(bytes);
        var bytesOutput = new BytesOutput();
        var inputStream = new InputStream(bytesInput);
        var outputStream = new OutputStream(bytesOutput);
        var pipe = new PipeTransfer(inputStream, outputStream);

        var done = TaskTestTools.startAsync(function () {
            Assert.equals("Hello world!", bytesOutput.getBytes());
        });

        pipe.transferAll()
            .onComplete(function (task) {
                task.getResult();

                done();
            })
            .handleException(function (exception) {
                Assert.fail(exception);
                throw exception;
            });
    }
}
