package plumekit.test.text.codecs;

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
}
