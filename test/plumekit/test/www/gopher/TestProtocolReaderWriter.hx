package plumekit.test.www.gopher;

import plumekit.stream.StreamReader;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import plumekit.www.gopher.ItemType;
import plumekit.www.gopher.DirectoryEntity;
import utest.Assert;
import plumekit.stream.MemoryStream;
import plumekit.www.gopher.ProtocolReaderWriter;


class TestProtocolReaderWriter {
    public function new() {
    }

    public function testSelector() {
        var stream = new MemoryStream();
        var protocol = new ProtocolReaderWriter(stream, stream);

        var done = TaskTestTools.startAsync();

        protocol.writeSelector("/test")
            .continueWith(function (task) {
                task.getResult();

                return protocol.readSelector();
            })
            .onComplete(function (task) {
                var selector = task.getResult();
                Assert.equals("/test", selector);

                done();
            })
            .handleException(TaskTestTools.exceptionHandler);
    }

    public function testDirectoryEntity() {
        var stream = new MemoryStream();
        var protocol = new ProtocolReaderWriter(stream, stream);

        var done = TaskTestTools.startAsync();
        var entity = new DirectoryEntity(
            ItemType.ImageFile,
            "example.png", "/example.png", "example.com", 70);

        protocol.writeDirectoryEntity(entity)
            .continueWith(function (task) {
                task.getResult();

                return protocol.readDirectoryEntity();
            })
            .onComplete(function (task) {
                switch (task.getResult()) {
                    case Some(entity):
                        Assert.equals("/example.png", entity.selector);
                    case None:
                        Assert.fail();
                }

                done();
            })
            .handleException(TaskTestTools.exceptionHandler);
    }

    public function baseTestFile(textMode:Bool) {
        var stream = new MemoryStream();
        var protocol = new ProtocolReaderWriter(stream, stream);
        var input = new BytesInput(Bytes.ofString("Hello world!"));
        var inputStream = new InputStream(input);

        var done = TaskTestTools.startAsync();

        protocol.putFile(inputStream, textMode).transferAll()
            .continueWith(function (task) {
                task.getResult();
                stream.close();
                var reader = new StreamReader(protocol.getFile(textMode));
                return reader.readAll();
            })
            .onComplete(function (task) {
                var bytes = task.getResult();
                Assert.equals("Hello world!", bytes.toString());

                done();
            })
            .handleException(TaskTestTools.exceptionHandler);
    }

    public function testFile() {
        baseTestFile(false);
    }

    public function testTextFile() {
        baseTestFile(true);
    }
}
