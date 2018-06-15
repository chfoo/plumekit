package plumekit.text;

import haxe.io.Bytes;
import plumekit.text.codec.ErrorMode;
import plumekit.text.codec.Registry;


class EncodingTools {
    public static function encode(text:String, encoding:String = "utf-8", ?errorMode:ErrorMode):Bytes {
        var encoder = Registry.getEncoder(encoding, errorMode);

        return encoder.encode(text);
    }

    public static function decode(data:Bytes, encoding:String = "utf-8", ?errorMode:ErrorMode):String {
        var decoder = Registry.getDecoder(encoding, errorMode);

        return decoder.decode(data);
    }
}
