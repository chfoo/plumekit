package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.DecoderRunner;
import plumekit.text.codec.Big5Decoder;


class TestBig5Decoder {
    public function new() {
    }

    public function testDecode() {
        var bytes = Bytes.alloc(7);
        bytes.set(0, " ".code);
        bytes.set(1, 0xA1); // ︾
        bytes.set(2, 0x70);
        bytes.set(3, 0xA4); // 一
        bytes.set(4, 0x40);
        bytes.set(5, 0xF9); // 灩
        bytes.set(6, 0xD0);

        var handler = new Big5Decoder();
        var decoder = new DecoderRunner(handler);

        Assert.equals(" ︾一灩", decoder.decode(bytes));
    }
}
