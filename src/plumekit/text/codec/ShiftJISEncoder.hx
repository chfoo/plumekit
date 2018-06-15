package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;

using plumekit.text.codec.CodecTools;


class ShiftJISEncoder implements Handler {
    var index:IMap<Int,Int>;

    public function new() {
        index = IndexLoader.getCodePointToPointerMap("jis0208",
            IndexLoaderFilter.ShiftJIS);
    }

    public function process(stream:Stream, codePoint:Int):Result {
        if (codePoint == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else if (codePoint.isASCII() || codePoint == 0x0080) {
            return Result.Token(codePoint);
        } else if (codePoint == 0x00A5) {
            return Result.Token(0x5C);
        } else if (codePoint == 0x203E) {
            return Result.Token(0x7E);
        } else if (codePoint.isInRange(0xFF61, 0xFF9F)) {
            return Result.Token(codePoint - 0xFF61 + 0xA1);
        }

        if (codePoint == 0x2212) {
            codePoint = 0xFF0D;
        }

        var pointer;

        if (index.exists(codePoint)) {
            pointer = index.get(codePoint);
        } else {
            return Result.Error(CodecTools.INT_NULL);
        }

        var lead = pointer.div(188);
        var leadOffset = lead < 0x1F ? 0x81 : 0xC1;
        var trail = pointer % 188;
        var offset = trail < 0x3F ? 0x40 : 0x41;
        return Result.Tokens([lead + leadOffset, trail + offset]);
    }

}
