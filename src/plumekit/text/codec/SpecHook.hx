package plumekit.text.codec;

import haxe.io.Bytes;


class SpecHook {
    public static function getDecoder(fallbackEncoding:String):Decoder {
        return new SpecDecoder(fallbackEncoding);
    }

    public static function getUTF8Decoder():Decoder {
        return new SpecUTF8Decoder();
    }

    public static function getUTF8WithoutBOMDecoder():Decoder {
        return Registry.getDecoder("utf-8");
    }

    public static function getUTF8WithoutBOMOrFailDecoder():Decoder {
        return Registry.getDecoder("utf-8", ErrorMode.Fatal);
    }

    public static function getEncoder(encoding:String):Encoder {
        return Registry.getEncoder(encoding, ErrorMode.HTML);
    }

    public static function getUTF8Encoder():Encoder {
        return Registry.getEncoder("utf-8");
    }

    public static function decode(input:Bytes, fallbackEncoding:String):String {
        return getDecoder(fallbackEncoding).decode(input);
    }

    public static function utf8Decode(input:Bytes):String {
        return getUTF8Decoder().decode(input);
    }

    public static function utf8WithoutBOMDecode(input:Bytes):String {
        return getUTF8WithoutBOMDecoder().decode(input);
    }

    public static function utf8WithoutBOMOrFailDecode(input:Bytes):String {
        return getUTF8WithoutBOMOrFailDecoder().decode(input);
    }

    public static function encode(input:String, encoding:String):Bytes {
        return getEncoder(encoding).encode(input);
    }

    public static function utf8Encode(input:String):Bytes {
        return getUTF8Encoder().encode(input);
    }
}
