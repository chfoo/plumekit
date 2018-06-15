package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;

using plumekit.text.codec.CodecTools;


private enum EncoderState {
    ASCII;
    Roman;
    JIS0208;
}


class ISO2022JPEncoder implements Handler {
    var indexJIS0208:IMap<Int,Int>;
    var indexISO2022JPKatakana:IMap<Int,Int>;
    var encoderState:EncoderState = ASCII;

    public function new() {
        indexJIS0208 = IndexLoader.getCodePointToPointerMap("jis0208");
        indexISO2022JPKatakana = IndexLoader.getCodePointToPointerMap(
            "iso-2022-jp-katakana");
    }

    public function process(stream:Stream, codePoint:Int):Result {
        if (codePoint == Stream.END_OF_STREAM && encoderState != ASCII) {
            stream.unshift(codePoint);
            encoderState = ASCII;

            return Result.Tokens([0x1B, 0x28, 0x42]);

        } else if (codePoint == Stream.END_OF_STREAM && encoderState == ASCII) {
            return Result.Finished;

        } else if ((encoderState == ASCII || encoderState == Roman)
                && (codePoint == 0x000E || codePoint == 0x000F ||
                codePoint == 0x001B)) {
            return Result.Error(0xFFFD);

        } else if (encoderState == ASCII && codePoint.isASCII()) {
            return Result.Token(codePoint);

        } else if (encoderState == Roman
                && ((codePoint.isASCII()
                    && codePoint != 0x005C && codePoint != 0x007E)
                || (codePoint == 0x00A5 || codePoint == 0x203E))) {
            if (codePoint.isASCII()) {
                return Result.Token(codePoint);
            } else if (codePoint == 0x00A5) {
                return Result.Token(0x5C);
            } else if (codePoint == 0x203E) {
                return Result.Token(0x7E);
            } else {
                throw "Shouldn't reach here";
            }

        } else if (codePoint.isASCII() && encoderState != ASCII) {
            stream.unshift(codePoint);
            encoderState = ASCII;
            return Result.Tokens([0x1B, 0x28, 0x42]);

        } else if ((codePoint == 0x00A5 || codePoint == 0x203E)
                && encoderState != Roman) {
            stream.unshift(codePoint);
            encoderState = Roman;
            return Result.Tokens([0x1B, 0x28, 0x4A]);
        }

        if (codePoint == 0x2212) {
            codePoint = 0xFF0D;
        }

        if (codePoint.isInRange(0xFF61, 0xFF9F)) {
            var pointer = codePoint - 0xFF61;
            codePoint = indexISO2022JPKatakana.get(pointer);
        }

        var pointer;

        if (indexJIS0208.exists(codePoint)) {
            pointer = indexJIS0208.get(codePoint);
        } else {
            pointer = CodecTools.INT_NULL;
        }

        if (pointer == CodecTools.INT_NULL) {
            return Result.Error(codePoint);
        }

        if (encoderState != JIS0208) {
            stream.unshift(codePoint);
            encoderState = JIS0208;
            return Result.Tokens([0x1B, 0x24, 0x42]);
        }

        var lead = pointer.div(94) + 0x21;
        var trail = pointer % 94 + 0x21;

        return Result.Tokens([lead, trail]);
    }
}
