package plumekit.test.stream;

import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import utest.Assert;


class TestInputStream {
    public function new() {
    }

    public function testBytesInput() {
        var bytes = Bytes.ofString("Hello world!");
        var bytesInput = new BytesInput(bytes);
        var stream = new InputStream(bytesInput);

        var done = TaskTestTools.startAsync();

        stream.readReady().onComplete(function (task) {
            var stream_ = task.getResult();
            Assert.equals(stream, stream_);

            var destBytes = Bytes.alloc(100);
            var bytesRead = stream.readInto(destBytes, 0, 5);

            Assert.same(Some(5), bytesRead);
            Assert.equals("Hello", destBytes.sub(0, 5).toString());

            stream.close();
            done();

        }).handleException(TaskTestTools.exceptionHandler);
    }
}
