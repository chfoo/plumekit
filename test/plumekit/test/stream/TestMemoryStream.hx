package plumekit.test.stream;

import haxe.io.Bytes;
import plumekit.stream.MemoryStream;
import plumekit.stream.StreamException.EndOfFileException;
import plumekit.stream.StreamReader;
import plumekit.stream.StreamWriter;
import utest.Assert;


class TestMemoryStream {
    public function new() {
    }

    public function testReadThenWrite() {
        var stream = new MemoryStream();
        var reader = new StreamReader(stream);
        var writer = new StreamWriter(stream);

        var done = TaskTestTools.startAsync();

        read(reader, done);
        write(writer);
    }

    public function testWriteThenRead() {
        var stream = new MemoryStream();
        var reader = new StreamReader(stream);
        var writer = new StreamWriter(stream);

        var done = TaskTestTools.startAsync();

        write(writer);
        read(reader, done);
    }

    public function testClose() {
        var stream = new MemoryStream();
        var reader = new StreamReader(stream);
        var writer = new StreamWriter(stream);

        var done = TaskTestTools.startAsync();

        stream.close();

        writer.write(Bytes.alloc(1))
            .continueWith(function (task) {
                Assert.raises(task.getResult, EndOfFileException);
                return reader.readOnce();
            })
            .onComplete(function (task) {
                switch (task.getResult()) {
                    case Some(bytes):
                        Assert.fail();
                    case None:
                        Assert.pass();
                }

                done();
            })
            .handleException(TaskTestTools.exceptionHandler);
    }

    public function testGetBytes() {
        var stream = new MemoryStream();
        var writer = new StreamWriter(stream);

        var done = TaskTestTools.startAsync(function () {
            Assert.equals("hello", stream.getBytes().toString());
        });

        writer.write(Bytes.ofString("hello"))
            .onComplete(function (task) {
                task.getResult();

                done();
            })
            .handleException(TaskTestTools.exceptionHandler);
    }

    function write(writer:StreamWriter) {
        writer.write(Bytes.ofString("Hello world!"))
            .handleException(TaskTestTools.exceptionHandler);
    }

    function read(reader:StreamReader, doneCallback:Void->Void) {
        reader.readOnce()
            .onComplete(function (task) {
                switch (task.getResult()) {
                    case Some(bytes):
                        Assert.equals("Hello world!", bytes.toString());
                    case None:
                        Assert.fail();
                }

                doneCallback();
            })
            .handleException(TaskTestTools.exceptionHandler);
    }
}
