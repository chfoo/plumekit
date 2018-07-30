package plumekit.text;

import plumekit.Exception;


class IntParser {
    static inline var MAX_INT_VALUE:UInt = 0xffffffff;

    public static function parseInt(text:String, radix:Int):UInt {
        if (text.length < 1) {
            throw new ValueException("Empty string");
        }

        var result:UInt = 0;

        for (index in 0...text.length) {
            var charInt = charCodeToInt(text.charCodeAt(index));

            if (charInt >= radix) {
                throw new ValueException("Character outside radix range");
            }

            var expResult = charInt * Math.pow(radix, text.length - 1 - index);

            if (result + expResult > MAX_INT_VALUE) {
                throw new NumericalRangeException("Number too large");
            }

            result += Std.int(expResult);
        }

        return result;
    }

    public static function charCodeToInt(char:Int):Int {
        if (char >= "0".code && char <= "9".code) {
            return char - "0".code;
        } else if (char >= "a".code && char <= "z".code) {
            char &= 0xdf; // 0b11011111, convert to uppercase
            return char - "A".code + 10;
        } else if (char >= "A".code) {
            return char - "A".code + 10;
        } else {
            throw new ValueException("Unknown character");
        }
    }
}
