package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;

using plumekit.text.codec.CodecTools;


class EUCKREncoder implements Handler {
    var index:IMap<Int,Int>;

    public function new(gbkFlag:Bool = false) {
        index = IndexLoader.getCodePointToPointerMap("euc-kr");
    }

    public function process(stream:Stream, codePoint:Int):Result {
        if (codePoint == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else if (codePoint.isASCII()) {
            return Result.Token(codePoint);
        }

        var pointer;

        if (index.exists(codePoint)) {
            pointer = index.get(codePoint);
        } else {
            pointer = CodecTools.INT_NULL;
        }

        if (pointer == CodecTools.INT_NULL) {
            return Result.Error(codePoint);
        }

        var lead = pointer.div(190) + 0x81;
        var trail = pointer % 190 + 0x41;
        return Result.Tokens([lead, trail]);
    }
}
