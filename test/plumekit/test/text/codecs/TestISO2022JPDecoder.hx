package plumekit.test.text.codecs;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.Decoder;
import plumekit.text.codec.ISO2022JPDecoder;


class TestISO2022JPDecoder {
    public function new() {
    }

    public function testDecode() {
        var bytes = Bytes.alloc(13);
        bytes.set(0, " ".code);
        bytes.set(1, 0x1B); // enter jis0208
        bytes.set(2, 0x24);
        bytes.set(3, 0x42);
        bytes.set(4, 0x24); // ぁ
        bytes.set(5, 0x21);
        bytes.set(6, 0x25); // ヶ
        bytes.set(7, 0x76);
        bytes.set(8, 0x21); // ；
        bytes.set(9, 0x28);
        bytes.set(10, 0x1B); // enter ascii
        bytes.set(11, 0x28);
        bytes.set(12, 0x42);

        var handler = new ISO2022JPDecoder();
        var decoder = new Decoder(handler);

        Assert.equals(" ぁヶ；", decoder.decode(bytes));
    }
}
