package plumekit.test.text.codecs;

import haxe.io.Bytes;
import plumekit.bindata.BaseEncoder;
import plumekit.Exception;
import plumekit.text.codec.Big5Decoder;
import plumekit.text.codec.Big5Encoder;
import plumekit.text.codec.EUCJPDecoder;
import plumekit.text.codec.EUCJPEncoder;
import plumekit.text.codec.EUCKRDecoder;
import plumekit.text.codec.EUCKREncoder;
import plumekit.text.codec.GB18030Decoder;
import plumekit.text.codec.GB18030Encoder;
import plumekit.text.codec.ISO2022JPDecoder;
import plumekit.text.codec.ISO2022JPEncoder;
import plumekit.text.codec.Registry;
import plumekit.text.codec.ReplacementDecoder;
import plumekit.text.codec.ShiftJISDecoder;
import plumekit.text.codec.ShiftJISEncoder;
import plumekit.text.codec.SingleByteDecoder;
import plumekit.text.codec.SingleByteEncoder;
import plumekit.text.codec.UTF8Decoder;
import plumekit.text.codec.UTF8Encoder;
import plumekit.text.codec.XUserDefinedDecoder;
import plumekit.text.codec.XUserDefinedEncoder;
import plumekit.text.TextException.EncodingException;
import utest.Assert;


class TestRegistry {
    public function new() {
    }

    public function testLabelToEncodingName() {
        Assert.equals("UTF-8", Registry.getEncodingName("Utf8"));
        Assert.equals("windows-1252", Registry.getEncodingName("latin1"));
    }

    public function testLabelToEncodingNameNotFound() {
        Assert.raises(function () {
            Registry.getEncodingName("invalid");
        }, ValueException);
    }

    public function testLabelToEncodingOutputName() {
        Assert.equals("UTF-8", Registry.getOutputEncodingName("UTF-8"));
        Assert.equals("UTF-8", Registry.getOutputEncodingName("UTF-16BE"));
    }

    public function testGetEncoderHandler() {
        Assert.is(Registry.getEncoderHandler("utf8"), UTF8Encoder);
        Assert.is(Registry.getEncoderHandler("latin2"), SingleByteEncoder);
        Assert.is(Registry.getEncoderHandler("gbk"), GB18030Encoder);
        Assert.is(Registry.getEncoderHandler("big5"), Big5Encoder);
        Assert.is(Registry.getEncoderHandler("euc-jp"), EUCJPEncoder);
        Assert.is(Registry.getEncoderHandler("iso-2022-jp"), ISO2022JPEncoder);
        Assert.is(Registry.getEncoderHandler("shift_jis"), ShiftJISEncoder);
        Assert.is(Registry.getEncoderHandler("euc-kr"), EUCKREncoder);
        Assert.is(Registry.getEncoderHandler("x-user-defined"), XUserDefinedEncoder);
    }

    public function testGetEncoderHandlerError() {
        Assert.raises(function () {
            Registry.getEncoderHandler("replacement");
        }, ValueException);
        Assert.raises(function () {
            Registry.getEncoderHandler("utf-16be");
        }, ValueException);
        Assert.raises(function () {
            Registry.getEncoderHandler("invalid");
        }, ValueException);
    }

    public function testGetDecoderHandler() {
        Assert.is(Registry.getDecoderHandler("utf8"), UTF8Decoder);
        Assert.is(Registry.getDecoderHandler("latin2"), SingleByteDecoder);
        Assert.is(Registry.getDecoderHandler("gbk"), GB18030Decoder);
        Assert.is(Registry.getDecoderHandler("big5"), Big5Decoder);
        Assert.is(Registry.getDecoderHandler("euc-jp"), EUCJPDecoder);
        Assert.is(Registry.getDecoderHandler("iso-2022-jp"), ISO2022JPDecoder);
        Assert.is(Registry.getDecoderHandler("shift_jis"), ShiftJISDecoder);
        Assert.is(Registry.getDecoderHandler("euc-kr"), EUCKRDecoder);
        Assert.is(Registry.getDecoderHandler("x-user-defined"), XUserDefinedDecoder);
        Assert.is(Registry.getDecoderHandler("replacement"), ReplacementDecoder);
    }

    public function testGetSpecDecoder() {
        var decoder = Registry.getSpecDecoder("latin1");

        Assert.equals("a", decoder.decode(Bytes.ofString("a")));
        Assert.equals("ab", decoder.decode(Bytes.ofString("ab")));
        Assert.equals("abc", decoder.decode(Bytes.ofString("abc")));

        var utf8BOMBytes = BaseEncoder.base16decode("EFBBBF61");
        Assert.equals("a", decoder.decode(utf8BOMBytes));

        var utf16BEBytes = BaseEncoder.base16decode("FEFF0061");
        Assert.equals("a", decoder.decode(utf16BEBytes));

        var utf16LEBytes = BaseEncoder.base16decode("FFFE6100");
        Assert.equals("a", decoder.decode(utf16LEBytes));
    }

    public function testGetSpecUTF8Decoder() {
        var decoder = Registry.getSpecUTF8Decoder();

        Assert.equals("a", decoder.decode(Bytes.ofString("a")));
        Assert.equals("ab", decoder.decode(Bytes.ofString("ab")));
        Assert.equals("abc", decoder.decode(Bytes.ofString("abc")));

        var utf8BOMBytes = BaseEncoder.base16decode("EFBBBF61");
        Assert.equals("a", decoder.decode(utf8BOMBytes));
    }

    public function testGetSpecUTF8WithoutBOMDecoder() {
        var decoder = Registry.getSpecUTF8WithoutBOMDecoder();

        Assert.equals("a", decoder.decode(Bytes.ofString("a")));
    }

    public function testGetSpecUTF8WithoutBOMOrFailDecoder() {
        var decoder = Registry.getSpecUTF8WithoutBOMOrFailDecoder();

        Assert.equals("a", decoder.decode(Bytes.ofString("a")));

        var badBytes = Bytes.alloc(1);
        badBytes.set(0, 0xFF);
        Assert.raises(decoder.decode.bind(badBytes), EncodingException);
    }

    public function testSpecEncoder() {
        var encoder = Registry.getSpecEncoder("latin1");

        var result = encoder.encode("a 💾");

        Assert.equals(0, Bytes.ofString("a &#128190;").compare(result));
    }

    public function testSpecUTF8Encoder() {
        var encoder = Registry.getSpecUTF8Encoder();

        var expected = BaseEncoder.base16decode("6120F09F92BE");
        var result = encoder.encode("a 💾");

        Assert.equals(0, expected.compare(result));
    }
}
