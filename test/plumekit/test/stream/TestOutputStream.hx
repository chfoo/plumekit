package plumekit.test.stream;

import utest.Assert;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import plumekit.stream.OutputStream;


class TestOutputStream {
    public function new() {
    }

    public function testBytesOutput() {
        var bytes = Bytes.ofString("Hello world!");
        var bytesOutput = new BytesOutput();
        var stream = new OutputStream(bytesOutput);

        var done = TaskTestTools.startAsync(function () {
            var resultBytes = bytesOutput.getBytes();

            Assert.equals(bytes.length, resultBytes.length);
            Assert.equals("Hello world!", resultBytes.toString());
        });

        stream.writeReady().onComplete(function (task) {
            var stream_ = task.getResult();

            Assert.equals(stream, stream_);
            stream.write(bytes, 0, bytes.length);
            stream.close();
            done();

        }).handleException(TaskTestTools.exceptionHandler);
    }
}
