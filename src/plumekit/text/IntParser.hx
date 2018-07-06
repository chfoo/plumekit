package plumekit.text;

import plumekit.Exception.ValueException;


class IntParser {
    public static function parseInt(text:String, radix:Int):Int {
        if (text.length < 1) {
            throw new ValueException("Empty string");
        }

        var result = 0;

        for (index in 0...text.length) {
            var charInt = charCodeToInt(text.charCodeAt(index));

            if (charInt >= radix) {
                throw new ValueException("Character outside radix range");
            }

            result += Std.int(charInt * Math.pow(radix, text.length - 1 - index));
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
