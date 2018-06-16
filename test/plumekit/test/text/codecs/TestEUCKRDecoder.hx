package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.Decoder;
import plumekit.text.codec.EUCKRDecoder;


class TestEUCKRDecoder {
    public function new() {
    }

    public function testDecode() {
        var bytes = Bytes.alloc(7);
        bytes.set(0, " ".code);
        bytes.set(1, 0xA1); // 、
        bytes.set(2, 0xA2);
        bytes.set(3, 0xA4); // ㄱ
        bytes.set(4, 0xA1);
        bytes.set(5, 0xA3); // ￦
        bytes.set(6, 0xDC);

        var handler = new EUCKRDecoder();
        var decoder = new Decoder(handler);

        Assert.equals(" 、ㄱ￦", decoder.decode(bytes));
    }
}
