package plumekit.url;

import haxe.io.Bytes;
import plumekit.text.CodePointTools;
import plumekit.text.CodePointTools.INT_NULL;

using unifill.Unifill;


class ParserTools {
    public static function splitOnByte(bytes:Bytes, byte:Int):Array<Bytes> {
        var output = [];

        var lowerIndex = 0;

        for (upperIndex in 0...bytes.length) {
            if (bytes.get(upperIndex) == byte) {
                output.push(bytes.sub(lowerIndex, upperIndex));
                lowerIndex = upperIndex;
            }
        }

        output.push(bytes.sub(lowerIndex, bytes.length));

        return output;
    }

    public static function isAnyCodePoint(codePoint:Int, candidates:String):Bool {
        if (codePoint == INT_NULL) {
            return false;
        }

        for (candidate in candidates.uIterator()) {
            if (codePoint == candidate) {
                return true;
            }
        }

        return false;
    }

    public static function isURLCodePoint(codePoint:Int):Bool {
        return CodePointTools.isASCIIAlphanumeric(codePoint);
    }

    public static function startsWithTwoHexDigits(text:String):Bool {
        return text.length >= 2
            && CodePointTools.isASCIIHexDigit(text.uCharCodeAt(0))
            && CodePointTools.isASCIIHexDigit(text.uCharCodeAt(1));
    }

    public static function startsWithByte(bytes:Bytes, byte:Int, ?byte2:Int):Bool {
        if (byte2 == null) {
            return bytes.length >= 1 && bytes.get(0) == byte;
        } else {
            return bytes.length >= 2 && bytes.get(0) == byte && bytes.get(1) == byte2;
        }
    }

    public static function endsWithByte(bytes:Bytes, byte:Int):Bool {
        return bytes.length >= 1 && bytes.get(bytes.length - 1) == byte;
    }

    public static function isSingleDotPathSegment(segment:String):Bool {
        segment = segment.toLowerCase();
        return segment == "." || segment == "%2e";
    }

    public static function isDoubleDotPathSegment(segment:String):Bool {
        segment = segment.toLowerCase();
        return segment == ".."
                || segment == ".%2e"
                || segment == "%2e."
                || segment == "%2e%2e";
    }

    public static function isWindowsDriveLetter(drive:String):Bool {
        return drive.length == 2
                && CodePointTools.isASCIIAlpha(drive.charCodeAt(0))
                && (drive.charAt(1) == ":" || drive.charAt(1) == "|");
    }

    public static function isNormalizedWindowsDriveLetter(drive:String):Bool {
        return drive.length == 2
                && CodePointTools.isASCIIAlpha(drive.charCodeAt(0))
                && drive.charAt(1) == ":";
    }

    public static function startsWithWindowsDriveLetter(drive:String):Bool {
        return drive.length >= 2
            && isWindowsDriveLetter(drive.substr(0, 2))
            && (drive.length == 2 ||
                isAnyCodePoint(drive.uCharCodeAt(2), "/\\?#"));
    }
}
