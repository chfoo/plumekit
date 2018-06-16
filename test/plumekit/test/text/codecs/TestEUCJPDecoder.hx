package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.DecoderRunner;
import plumekit.text.codec.EUCJPDecoder;


class TestEUCJPDecoder {
    public function new() {
    }

    public function testDecode() {
        var bytes = Bytes.alloc(8);
        bytes.set(0, " ".code);
        bytes.set(1, 0xA1); // 、
        bytes.set(2, 0xA2);
        bytes.set(3, 0xB0); // 亜
        bytes.set(4, 0xA1);
        bytes.set(5, 0x8F); // 丂
        bytes.set(6, 0xB0);
        bytes.set(7, 0xA1);

        var handler = new EUCJPDecoder();
        var decoder = new DecoderRunner(handler);

        Assert.equals(" 、亜丂", decoder.decode(bytes));
    }
}
