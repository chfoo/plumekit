package plumekit.test.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import plumekit.stream.Source;
import plumekit.stream.StreamReader;
import plumekit.stream.TextReader;
import plumekit.stream.Transformer;
import utest.Assert;

using plumekit.stream.PipeTools;


class DoublerTransformer implements Transformer {
    var source:Source;
    var reader:StreamReader;

    public function new() {
    }

    public function prepare(source:Source) {
        this.source = source;
        reader = new StreamReader(source);
    }

    public function transform(amount:Int):Task<Option<Bytes>> {
        return reader.readOnce(amount).continueWith(readerCallback);
    }

    function readerCallback(task:Task<Option<Bytes>>) {
        switch (task.getResult()) {
            case Some(chunk):
                if (chunk.length == 0) {
                    return TaskTools.fromResult(None);
                }

                var newChunk = Bytes.alloc(chunk.length * 2);

                for (index in 0...chunk.length) {
                    newChunk.set(index * 2, chunk.get(index));
                    newChunk.set(index * 2 + 1, chunk.get(index));
                }

                return TaskTools.fromResult(Some(newChunk));
            case None:
                return TaskTools.fromResult(None);
        }
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
        var done = TaskTestTools.startAsync();

        textReader.readAll()
            .onComplete(function (task) {
                var text = task.getResult();

                Assert.equals("HHeelllloo  wwoorrlldd!!-END-", text);
                done();
            })
            .handleException(TaskTestTools.exceptionHandler);
    }
}
