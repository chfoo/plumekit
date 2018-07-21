package plumekit.url;

import plumekit.text.IntParser;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import unifill.CodePoint;
import plumekit.text.codec.Registry;
import plumekit.text.CodePointTools.INT_NULL;

using StringTools;
using plumekit.text.CodePointTools;


class PercentEncoder {
    public static function utf8PercentEncode(codePoint:Int, predicate:Int->Bool):String {
        var charText = CodePoint.fromInt(codePoint).toString();

        if (!predicate(codePoint)) {
            return charText;
        }
        var encoder = Registry.getSpecUTF8Encoder();
        var bytes = encoder.encode(charText);

        var buf = new StringBuf();

        for (index in 0...bytes.length) {
            buf.add(percentEncode(bytes.get(index)));
        }

        return buf.toString();
    }

    public static function percentEncode(byte:Int):String {
        return '%${byte.hex(2)}';
    }

    public static function stringPercentDecode(input:String):Bytes {
        var encoder = Registry.getSpecUTF8Encoder();

        return percentDecode(encoder.encode(input));
    }

    public static function percentDecode(input:Bytes):Bytes {
        var outputBuf = new BytesBuffer();
        var index = 0;

        while (index < input.length) {
            var byte = input.get(index);
            var byteNext = index < input.length ? input.get(index + 1) : INT_NULL;
            var byteNext2 = index < input.length ? input.get(index + 2) : INT_NULL;

            if (byte != "%".code) {
                outputBuf.addByte(byte);
            } else if (byte == "%".code
                    && (!byteNext.isASCIIAlphanumeric()
                    || !byteNext2.isASCIIAlphanumeric())) {
                outputBuf.addByte(byte);
            } else {
                var bytePoint = IntParser.charCodeToInt(byteNext) << 4
                    | IntParser.charCodeToInt(byteNext2);
                outputBuf.addByte(bytePoint);
                index += 2;
            }
        }

        return outputBuf.getBytes();
    }
}
