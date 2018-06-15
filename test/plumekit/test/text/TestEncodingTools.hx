package plumekit.test.text;

import haxe.io.Bytes;
import utest.Assert;
import plumekit.text.codec.ErrorMode;
import plumekit.text.TextExceptions;

using plumekit.text.EncodingTools;


class TestEncodingTools {
    public function new() {
    }

    public function testEncodeDecode() {
        Assert.equals("Hello world! 🦌", "Hello world! 🦌".encode().decode());
    }

    public function testEncodeError() {
        Assert.raises(function () {
            "Hello world! 🦌".encode("latin1", ErrorMode.Fatal);
        }, EncodingException);
    }

    public function testDecodeError() {
        var data = Bytes.alloc(4);
        data.set(3, 0xff);
        Assert.raises(function () {
            data.decode("utf8", ErrorMode.Fatal);
        });
    }
}
