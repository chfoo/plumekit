package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;

using plumekit.text.codec.CodecTools;


class Big5Decoder implements Handler {
    var index:IMap<Int,Int>;
    var big5lead = 0;

    public function new() {
        index = IndexLoader.getPointerToCodePointMap("big5");
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM && big5lead != 0) {
            big5lead = 0;
            return Result.Error(CodecTools.INT_NULL);
        } else if (byte == Stream.END_OF_STREAM && big5lead == 0) {
            return Result.Finished;
        }

        if (big5lead != 0) {
            return processBig5Lead(stream, byte);
        }

        if (byte.isASCII()) {
            return Result.Token(byte);
        }

        if (byte >= 0x81 && byte <= 0xFE) {
            big5lead = byte;
            return Result.Continue;
        }

        return Result.Error(CodecTools.INT_NULL);
    }

    function processBig5Lead(stream:Stream, byte:Int) {
        var lead = big5lead;
        var pointer = CodecTools.INT_NULL;
        big5lead = 0;

        var offset = byte < 0x7F ? 0x40 : 0x62;

        if (byte.isInRange(0x40, 0x7E) || byte.isInRange(0xA1, 0xFE)) {
            pointer = (lead - 0x81) * 157 + (byte - offset);
        }

        switch (pointer) {
            case 1133:
                return Result.Tokens([0x00CA, 0x030C]);
            case 1135:
                return Result.Tokens([0x00CA, 0x030C]);
            case 1164:
                return Result.Tokens([0x00EA, 0x0304]);
            case 1166:
                return Result.Tokens([0x00EA, 0x030C]);
        }

        var codePoint;

        if (pointer == CodecTools.INT_NULL) {
            codePoint = CodecTools.INT_NULL;
        } else {
            if (index.exists(pointer)) {
                codePoint = index.get(pointer);
            } else {
                codePoint = CodecTools.INT_NULL;
            }
        }

        if (codePoint != CodecTools.INT_NULL) {
            return Result.Token(codePoint);
        }

        if (byte.isASCII()) {
            stream.unshift(byte);
        }

        return Result.Error(CodecTools.INT_NULL);
    }
}
