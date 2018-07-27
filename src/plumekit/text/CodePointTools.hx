package plumekit.text;

import haxe.io.Bytes;


class CodePointTools {
    public static inline var INT_NULL = -1;

    public static function isInRange(char:Int, lower:Int, upper:Int):Bool {
        return char >= lower && char <= upper;
    }

    public static function isSurrogate(char:Int):Bool {
        return isInRange(char, 0xD800, 0xDFFF);
    }

    public static function isScalarValue(char:Int):Bool {
        return !isSurrogate(char);
    }

    public static function isNoncharacter(char:Int):Bool {
        return isInRange(char, 0xFDD0, 0xFDEF)
            || char == 0xFFFE
            || char == 0xFFFF
            || char == 0x1FFFE
            || char == 0x1FFFF
            || char == 0x2FFFE
            || char == 0x2FFFF
            || char == 0x3FFFE
            || char == 0x3FFFF
            || char == 0x4FFFE
            || char == 0x4FFFF
            || char == 0x5FFFE
            || char == 0x5FFFF
            || char == 0x6FFFE
            || char == 0x6FFFF
            || char == 0x7FFFE
            || char == 0x7FFFF
            || char == 0x8FFFE
            || char == 0x8FFFF
            || char == 0x9FFFE
            || char == 0x9FFFF
            || char == 0xAFFFE
            || char == 0xAFFFF
            || char == 0xBFFFE
            || char == 0xBFFFF
            || char == 0xCFFFE
            || char == 0xCFFFF
            || char == 0xDFFFE
            || char == 0xDFFFF
            || char == 0xEFFFE
            || char == 0xEFFFF
            || char == 0xFFFFE
            || char == 0xFFFFF
            || char == 0x10FFFE
            || char == 0x10FFFF;
    }

    public static function isASCII(char:Int):Bool {
        return isInRange(char, 0x00, 0x7F);
    }

    public static function isASCIITabOrNewline(char:Int):Bool {
        return char == 0x09 || char == 0x0A || char == 0x0D;
    }

    public static function isASCIIWhitespace(char:Int):Bool {
        return char == 0x09
            || char == 0x0A
            || char == 0x0C
            || char == 0x0D
            || char == 0x20;
    }

    public static function isC0Control(char:Int):Bool {
        return isInRange(char, 0x00, 0x1F);
    }

    public static function isC0ControlOrSpace(char:Int):Bool {
        return char == " ".code || isC0Control(char);
    }

    public static function isControl(char:Int):Bool {
        return isC0Control(char) || isInRange(char, 0x7F, 0x9F);
    }

    public static function isASCIIDigit(char:Int):Bool {
        return isInRange(char, 0x30, 0x39);
    }

    public static function isASCIIUpperHexDigit(char:Int):Bool {
        return isASCIIDigit(char) || isInRange(char, 0x30, 0x39);
    }

    public static function isASCIILowerHexDigit(char:Int):Bool {
        return isASCIIDigit(char) || isInRange(char, 0x61, 0x66);
    }

    public static function isASCIIHexDigit(char:Int):Bool {
        return isASCIIUpperHexDigit(char) || isASCIILowerHexDigit(char);
    }

    public static function isASCIIUpperAlpha(char:Int):Bool {
        return isInRange(char, 0x41, 0x5a);
    }

    public static function isASCIILowerAlpha(char:Int):Bool {
        return isInRange(char, 0x61, 0x7a);
    }

    public static function isASCIIAlpha(char:Int):Bool {
        return isASCIIUpperAlpha(char) || isASCIILowerAlpha(char);
    }

    public static function isASCIIAlphanumeric(char:Int):Bool {
        return isASCIIDigit(char) || isASCIIAlpha(char);
    }

    public static function toASCIILowercase(char:Int):Int {
        if (isASCIIAlpha(char)) {
            return char | 0x20; // 0b00100000
        } else {
            return char;
        }
    }

    public static function toASCIIUppercase(char:Int):Int {
        if (isASCIIAlpha(char)) {
            return char & ~0x20;
        } else {
            return char;
        }
    }

    public static function isomorphicDecode(bytes:Bytes):String {
        var buf = new StringBuf();

        for (index in 0...bytes.length) {
            buf.addChar(bytes.get(index));
        }

        return buf.toString();
    }
}
