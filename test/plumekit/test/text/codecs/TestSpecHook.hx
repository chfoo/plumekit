package plumekit.test.text.codecs;

import haxe.io.Bytes;
import plumekit.bindata.BaseEncoder;
import plumekit.text.codec.SpecHook;
import plumekit.text.TextException.EncodingException;
import utest.Assert;


class TestSpecHook {
    public function new() {
    }

    public function testSpecDecoder() {
        var decoder = SpecHook.getDecoder("latin1");

        Assert.equals("a", decoder.decode(Bytes.ofString("a")));
        Assert.equals("ab", decoder.decode(Bytes.ofString("ab")));
        Assert.equals("abc", decoder.decode(Bytes.ofString("abc")));

        var utf8BOMBytes = BaseEncoder.base16decode("EFBBBF61");
        Assert.equals("a", SpecHook.decode(utf8BOMBytes, "latin1"));

        var utf16BEBytes = BaseEncoder.base16decode("FEFF0061");
        Assert.equals("a", SpecHook.decode(utf16BEBytes, "latin1"));

        var utf16LEBytes = BaseEncoder.base16decode("FFFE6100");
        Assert.equals("a", SpecHook.decode(utf16LEBytes, "latin1"));
    }

    public function testSpecUTF8Decoder() {
        var decoder = SpecHook.getUTF8Decoder();

        Assert.equals("a", decoder.decode(Bytes.ofString("a")));
        Assert.equals("ab", decoder.decode(Bytes.ofString("ab")));
        Assert.equals("abc", decoder.decode(Bytes.ofString("abc")));

        var utf8BOMBytes = BaseEncoder.base16decode("EFBBBF61");
        Assert.equals("a", SpecHook.utf8Decode(utf8BOMBytes));
    }

    public function testSpecUTF8WithoutBOMDecoder() {
        Assert.equals("a", SpecHook.utf8WithoutBOMDecode(Bytes.ofString("a")));
    }

    public function testGetSpecUTF8WithoutBOMOrFailDecoder() {
        Assert.equals(
            "a", SpecHook.utf8WithoutBOMOrFailDecode(Bytes.ofString("a")));

        var badBytes = Bytes.alloc(1);
        badBytes.set(0, 0xFF);
        Assert.raises(
            SpecHook.utf8WithoutBOMOrFailDecode.bind(badBytes),
            EncodingException);
    }

    public function testSpecEncoder() {
        var result = SpecHook.encode("a 💾", "latin1");

        Assert.equals(0, Bytes.ofString("a &#128190;").compare(result));
    }

    public function testSpecUTF8Encoder() {
        var expected = BaseEncoder.base16decode("6120F09F92BE");
        var result = SpecHook.utf8Encode("a 💾");

        Assert.equals(0, expected.compare(result));
    }
}
