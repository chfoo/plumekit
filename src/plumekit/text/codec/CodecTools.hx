package plumekit.text.codec;


class CodecTools {
    public static inline var INT_NULL = -1;

    public static function isASCII(token:Int):Bool {
        return token <= 0x7f;
    }

    public static function isInRange(token:Int, lower:Int, upper:Int):Bool {
        return token >= lower && token <= upper;
    }

    public static function div(num:Int, divisor:Int):Int {
        return Std.int(num / divisor);
    }
}
