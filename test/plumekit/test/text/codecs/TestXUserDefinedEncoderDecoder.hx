package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.Decoder;
import plumekit.text.codec.Encoder;
import plumekit.text.codec.XUserDefinedDecoder;
import plumekit.text.codec.XUserDefinedEncoder;


class TestXUserDefinedEncoderDecoder {
    public function new() {
    }

    public function testEncodeDecode() {
        var decoderHandler = new XUserDefinedDecoder();
        var decoder = new Decoder(decoderHandler);

        var encoderHandler = new XUserDefinedEncoder();
        var encoder = new Encoder(encoderHandler);

        var data = Bytes.alloc(256);

        for (index in 0...256) {
            data.set(index, index);
        }

        var text = decoder.decode(data);
        var resultData = encoder.encode(text);

        Assert.equals(0, data.compare(resultData));
    }
}
