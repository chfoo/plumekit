package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;
import plumekit.text.CodePointTools.INT_NULL;

using plumekit.text.codec.CodecTools;
using plumekit.text.CodePointTools;


class EUCJPEncoder implements Handler {
    var index:IMap<Int,Int>;

    public function new(gbkFlag:Bool = false) {
        index = IndexLoader.getCodePointToPointerMap("jis0208");
    }

    public function process(stream:Stream, codePoint:Int):Result {
        if (codePoint == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else if (codePoint.isASCII()) {
            return Result.Token(codePoint);
        } else if (codePoint == 0x00A5) {
            return Result.Token(0x5C);
        } else if (codePoint == 0x203E) {
            return Result.Token(0x7E);
        } else if (codePoint.isInRange(0xFF61, 0xFF9F)) {
            return Result.Tokens([0x8E, codePoint - 0xFF61 + 0xA1]);
        } else if (codePoint == 0x2212) {
            codePoint = 0xFF0D;
        }

        var pointer;

        if (index.exists(codePoint)) {
            pointer = index.get(codePoint);
        } else {
            pointer = INT_NULL;
        }

        if (pointer == INT_NULL) {
            return Result.Error(codePoint);
        }

        var lead = pointer.div(94) + 0xA1;
        var trail = pointer % 94 + 0xA1;
        return Result.Tokens([lead, trail]);
    }
}
