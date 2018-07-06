package plumekit.url;


class ParserTools {
    public static inline var INT_NULL = - 1;

    public static function isASCII(char:Int):Bool {
        return char <= 0x7f;
    }

    public static function isInRange(char:Int, lower:Int, upper:Int):Bool {
        return char >= lower && char <= upper;
    }

    public static function isASCIIHexDigit(char:Int):Bool {
        return isASCIIDigit(char)
            || isInRange(char, 0x41, 0x46)
            || isInRange(char, 0x61, 0x66);
    }

    public static function isASCIIDigit(char:Int):Bool {
        return isInRange(char, 0x30, 0x39);
    }
}
