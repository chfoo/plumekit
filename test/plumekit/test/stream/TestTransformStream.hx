package plumekit.test.stream;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import plumekit.stream.TextReader;
import plumekit.stream.Transformer;
import utest.Assert;

using plumekit.stream.PipeTools;


class DoublerTransformer implements Transformer {
    public function new() {
    }

    public function transform(chunk:Bytes):Bytes {
        var newChunk = Bytes.alloc(chunk.length * 2);

        for (index in 0...chunk.length) {
            newChunk.set(index * 2, chunk.get(index));
            newChunk.set(index * 2 + 1, chunk.get(index));
        }

        return newChunk;
    }

    public function flush():Bytes {
        return Bytes.ofString("-END-");
    }
}


class TestTransformStream {
    public function new() {
    }

    public function testIdentity() {
        var bytes = Bytes.ofString("Hello world!");
        var bytesInput = new BytesInput(bytes);
        var inputStream = new InputStream(bytesInput)
            .withTransform(new DoublerTransformer());
        var textReader = new TextReader(inputStream);
        var done = Assert.createAsync();

        textReader.readAll()
            .onComplete(function (task) {
                var text = task.getResult();

                Assert.equals("HHeelllloo  wwoorrlldd!!-END-", text);
                done();
            })
            .handleException(exceptionHandler);
    }

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
