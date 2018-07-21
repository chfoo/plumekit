package plumekit.url;

using plumekit.text.CodePointTools;


class PercentEncodeSet {
    public static function c0Control(codePoint:Int):Bool {
        return codePoint.isC0Control() || codePoint > "~".code;
    }

    public static function fragment(codePoint:Int):Bool {
        return c0Control(codePoint)
            || codePoint == " ".code
            || codePoint == "\"".code
            || codePoint == "<".code
            || codePoint == ">".code
            || codePoint == "`".code;
    }

    public static function path(codePoint:Int):Bool {
        return fragment(codePoint)
            || codePoint == "#".code
            || codePoint == "?".code
            || codePoint == "{".code
            || codePoint == "}".code;
    }

    public static function userinfo(codePoint:Int):Bool {
        return path(codePoint)
            || codePoint == "/".code
            || codePoint == ":".code
            || codePoint == ";".code
            || codePoint == "=".code
            || codePoint == "@".code
            || codePoint == "[".code
            || codePoint == "\\".code
            || codePoint == "]".code
            || codePoint == "^".code
            || codePoint == "|".code;
    }
}
