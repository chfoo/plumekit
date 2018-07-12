package plumekit.test.www.gopher;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.stream.InputStream;
import plumekit.stream.TextReader;
import plumekit.www.gopher.TextFileEscaper;
import utest.Assert;

using plumekit.stream.PipeTools;


class TestTextFileEscaper {
    public function new() {
    }

    public function test() {
        var bytes = new BytesInput(Bytes.ofString(SampleText.TEXT_1));
        var stream = new InputStream(bytes)
            .withTransform(new TextFileEscaper());
        var reader = new TextReader(stream);

        var done = TaskTestTools.startAsync();

        reader.readAll()
            .onComplete(function (task) {
                var text = task.getResult();

                Assert.equals(SampleText.ENCODED_TEXT_1, text);

                done();
            })
            .handleException(exceptionHandler);
    }

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
