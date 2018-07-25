package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;
import plumekit.text.CodePointTools.INT_NULL;
import resdb.Database;

using plumekit.text.CodePointTools;
using plumekit.internal.IntAdapter;


class GB18030Decoder implements Handler {
    var index:IMap<Int,Int>;
    var first = 0;
    var second = 0;
    var third = 0;
    var rangesDatabase:Database;

    public function new() {
        index = IndexLoader.getPointerToCodePointMap("gb18030");
        rangesDatabase = IndexLoader.getDatabase("gb18030-ranges");
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM
                && first == 0 && second == 0 && third == 0) {
            return Result.Finished;
        } else if (byte == Stream.END_OF_STREAM
                && (first != 0 || second != 0 || third != 0)) {
            first = second = third = 0;
            return Result.Error(INT_NULL);
        } else if (third != 0) {
            return processThirdNotZero(stream, byte);
        } else if (second != 0) {
            return processSecondNotZero(stream, byte);
        } else if (first != 0) {
            return processFirstNotZero(stream, byte);
        }

        if (byte.isASCII()) {
            return Result.Token(byte);
        } else if (byte == 0x80) {
            return Result.Token(0x20ac);
        } else if (byte.isInRange(0x81, 0xFE)) {
            first = byte;
            return Result.Continue;
        }

        return Result.Error(INT_NULL);
    }

    function processThirdNotZero(stream:Stream, byte:Int) {
        if (!(byte >= 0x30 && byte <= 0x39)) {
            stream.unshift(byte);
            stream.unshift(third);
            stream.unshift(second);

            first = second = third = 0;

            return Result.Error(INT_NULL);
        }

        var pointer = ((first - 0x81) * (10 * 126 * 10))
            + ((second - 0x30) * (10 * 126))
            + ((third - 0x81) * 10)
            + byte - 0x30;

        var codePoint = getRangesCodePoint(pointer);

        first = second = third = 0;

        if (codePoint == INT_NULL) {
            return Result.Error(INT_NULL);
        }

        return Result.Token(codePoint);
    }

    function processSecondNotZero(stream:Stream, byte:Int) {
        if (byte.isInRange(0x81, 0xFE)) {
            third = byte;
            return Result.Continue;
        }

        stream.unshift(second);
        stream.unshift(byte);
        first = second = 0;

        return Result.Error(INT_NULL);
    }

    function processFirstNotZero(stream:Stream, byte:Int) {
        if (byte.isInRange(0x30, 0x39)) {
            second = byte;
            return Result.Continue;
        }

        var lead = first;
        var pointer = INT_NULL;
        first = 0;
        var offset = byte < 0x7f ? 0x40 : 0x41;

        if (byte.isInRange(0x40, 0x7E) || byte.isInRange(0x80, 0xFE)) {
            pointer = (lead - 0x81) * 190 + (byte - offset);
        }

        var codePoint;

        if (pointer == INT_NULL) {
            codePoint = INT_NULL;
        } else {
            if (index.exists(pointer)) {
                codePoint = index.get(pointer);
            } else {
                codePoint = INT_NULL;
            }
        }

        if (codePoint != INT_NULL) {
            return Result.Token(codePoint);
        }

        if (byte.isASCII()) {
            stream.unshift(byte);
        }

        return Result.Error(INT_NULL);
    }

    function getRangesCodePoint(pointer:Int):Int {
        if (pointer > 39419 && pointer < 189000 || pointer > 1237575) {
            return INT_NULL;
        }

        if (pointer == 7475) {
            return 0xE7C7;
        }

        var offset = INT_NULL;
        var codePointOffset = INT_NULL;
        var cursor = rangesDatabase.intCursor();

        while (true) {
            var cursorPointer = cursor.key();
            var cursorCodePoint = cursor.value();

            if (cursorPointer <= pointer) {
                offset = cursorPointer;
                codePointOffset = cursorCodePoint;
            } else {
                break;
            }

            switch cursor.next() {
                case Some(key): continue;
                case None: break;
            }
        }

        return codePointOffset + pointer - offset;
    }
}
