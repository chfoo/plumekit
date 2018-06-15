package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;

using plumekit.text.codec.CodecTools;


class Big5Encoder implements Handler {
    var index:IMap<Int,Int>;

    public function new(gbkFlag:Bool = false) {
        index = IndexLoader.getCodePointToPointerMap("big5",
            IndexLoaderFilter.Big5);
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

        var lead = pointer.div(157) + 0x81;
        var trail = pointer % 157;
        var offset = trail < 0x3F ? 0x40 : 0x62;
        return Result.Tokens([lead, trail + offset]);
    }
}
