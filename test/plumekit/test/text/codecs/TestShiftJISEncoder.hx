package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.EncoderRunner;
import plumekit.text.codec.ShiftJISEncoder;


class TestShiftJISEncoder {
    public function new() {
    }

    public function testEncode() {
        var bytes = Bytes.alloc(7);
        bytes.set(0, " ".code);
        bytes.set(1, 0x81); // 、
        bytes.set(2, 0x41);
        bytes.set(3, 0x82); // あ
        bytes.set(4, 0xA0);
        bytes.set(5, 0xFC); // 髜
        bytes.set(6, 0x40);

        var handler = new ShiftJISEncoder();
        var encoder = new EncoderRunner(handler);

        Assert.equals(0, bytes.compare(encoder.encode(" 、あ髜")));
    }
}
