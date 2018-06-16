package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.EncoderRunner;
import plumekit.text.codec.Big5Encoder;


class TestBig5Encoder {
    public function new() {
    }

    public function testEncode() {
        var bytes = Bytes.alloc(7);
        bytes.set(0, " ".code);
        bytes.set(1, 0xA1); // ︾
        bytes.set(2, 0x70);
        bytes.set(3, 0xA4); // 一
        bytes.set(4, 0x40);
        bytes.set(5, 0xF9); // 灩
        bytes.set(6, 0xD0);

        var handler = new Big5Encoder();
        var encoder = new EncoderRunner(handler);

        Assert.equals(0, bytes.compare(encoder.encode(" ︾一灩")));
    }
}
