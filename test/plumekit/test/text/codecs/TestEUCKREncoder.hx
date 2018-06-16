package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.Encoder;
import plumekit.text.codec.EUCKREncoder;


class TestEUCKREncoder {
    public function new() {
    }

    public function testEncode() {
        var bytes = Bytes.alloc(7);
        bytes.set(0, " ".code);
        bytes.set(1, 0xA1); // 、
        bytes.set(2, 0xA2);
        bytes.set(3, 0xA4); // ㄱ
        bytes.set(4, 0xA1);
        bytes.set(5, 0xA3); // ￦
        bytes.set(6, 0xDC);

        var handler = new EUCKREncoder();
        var encoder = new Encoder(handler);

        Assert.equals(0, bytes.compare(encoder.encode(" 、ㄱ￦")));
    }
}
