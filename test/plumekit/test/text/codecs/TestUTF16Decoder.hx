package plumekit.test.text.codecs;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Eof;
import haxe.Resource;
import utest.Assert;
import plumekit.bindata.BaseEncoder;
import plumekit.text.codec.DecoderRunner;
import plumekit.text.codec.UTF16Decoder;


class TestUTF16Decoder {
    public function new() {
    }

    public function testlittleEndian() {
        var decoderHandler = new UTF16Decoder();
        var decoder = new DecoderRunner(decoderHandler);

        var result = decoder.decode(
            BaseEncoder.base16decode(
                "480065006C006C006F00200077006F0072006C006400210020003DD8BEDC",
            true));

        Assert.equals("Hello world! 💾", result);
    }

    public function testBigEndian() {
        var decoderHandler = new UTF16Decoder(true);
        var decoder = new DecoderRunner(decoderHandler);

        var result = decoder.decode(
            BaseEncoder.base16decode(
                "00480065006C006C006F00200077006F0072006C006400210020D83DDCBE",
            true));

        Assert.equals("Hello world! 💾", result);
    }
}
