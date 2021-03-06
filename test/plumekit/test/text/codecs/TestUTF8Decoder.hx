package plumekit.test.text.codecs;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Eof;
import haxe.Resource;
import utest.Assert;
import plumekit.bindata.BaseEncoder;
import plumekit.text.codec.DecoderRunner;
import plumekit.text.codec.UTF8Decoder;


class TestUTF8Decoder {
    public function new() {
    }

    public function testSimple() {
        var decoderHandler = new UTF8Decoder();
        var decoder = new DecoderRunner(decoderHandler);

        var result = decoder.decode(
            BaseEncoder.base16decode("48656c6c6f20776f726c642120f09f92be", true));

        Assert.equals("Hello world! 💾", result);
    }

    public function testTestFile() {
        var decoderHandler = new UTF8Decoder();
        var decoder = new DecoderRunner(decoderHandler);
        var sourceInput = new BytesInput(Resource.getBytes("test/samples/UTF-8-test.txt"));
        var outputBuffer = new StringBuf();

        var buffer = Bytes.alloc(1024);

        while (true) {
            var amountRead;

            try {
                amountRead = sourceInput.readBytes(buffer, 0, buffer.length);
            } catch (exception:Eof) {
                break;
            }

            outputBuffer.add(decoder.decode(buffer.sub(0, amountRead), true));
        }

        outputBuffer.add(decoder.flush());
        var output = outputBuffer.toString();

        // trace(output);

        Assert.isTrue(output.indexOf("THE END    ") >= 0);
        Assert.equals("|\n", output.substr(output.length - 2, 2));
    }
}
