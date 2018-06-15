package plumekit.test.text.codecs;

import plumekit.Exception;
import plumekit.text.codec.Big5Decoder;
import plumekit.text.codec.Big5Encoder;
import plumekit.text.codec.EUCJPDecoder;
import plumekit.text.codec.EUCJPEncoder;
import plumekit.text.codec.GB18030Decoder;
import plumekit.text.codec.GB18030Encoder;
import plumekit.text.codec.ISO2022JPDecoder;
import plumekit.text.codec.ISO2022JPEncoder;
import plumekit.text.codec.Registry;
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
        Assert.equals("UTF-8", Registry.labelToEncodingName("Utf8"));
        Assert.equals("windows-1252", Registry.labelToEncodingName("latin1"));
    }

    public function testLabelToEncodingNameNotFound() {
        Assert.raises(function () {
            Registry.labelToEncodingName("invalid");
        }, ValueException);
    }

    public function testGetEncoderHandler() {
        Assert.is(Registry.getEncoderHandler("utf8"), UTF8Encoder);
        Assert.is(Registry.getEncoderHandler("latin2"), SingleByteEncoder);
        Assert.is(Registry.getEncoderHandler("gbk"), GB18030Encoder);
        Assert.is(Registry.getEncoderHandler("big5"), Big5Encoder);
        Assert.is(Registry.getEncoderHandler("euc-jp"), EUCJPEncoder);
        Assert.is(Registry.getEncoderHandler("iso-2022-jp"), ISO2022JPEncoder);
        // Assert.is(Registry.getEncoderHandler("shift_jis"), Todo);
        // Assert.is(Registry.getEncoderHandler("euc-kr"), Todo);
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
        // Assert.is(Registry.getDecoderHandler("shift_jis"), Todo);
        // Assert.is(Registry.getDecoderHandler("euc-kr"), Todo);
        Assert.is(Registry.getDecoderHandler("x-user-defined"), XUserDefinedDecoder);
    }
}
