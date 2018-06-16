package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.EncoderRunner;
import plumekit.text.codec.EUCJPEncoder;


class TestEUCJPEncoder {
    public function new() {
    }

    public function testEncode() {
        var bytes = Bytes.alloc(5);
        bytes.set(0, " ".code);
        bytes.set(1, 0xA1); // 、
        bytes.set(2, 0xA2);
        bytes.set(3, 0xB0); // 亜
        bytes.set(4, 0xA1);
        // Not supported in the encoder:
        // bytes.set(5, 0x8F); // 丂
        // bytes.set(6, 0xB0);
        // bytes.set(7, 0xA1);

        var handler = new EUCJPEncoder();
        var encoder = new EncoderRunner(handler);

        Assert.equals(0, bytes.compare(encoder.encode(" 、亜")));
    }
}
