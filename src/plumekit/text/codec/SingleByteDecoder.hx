package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.CodePointTools.INT_NULL;

using plumekit.text.CodePointTools;


class SingleByteDecoder implements Handler {
    var table:IMap<Int,Int>;

    public function new(encoding:String) {
        table = IndexLoader.getPointerToCodePointMap(encoding);
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else if (byte.isASCII()) {
            return Result.Token(byte);
        } else {
            var pointer = byte - 0x80;
            var codePoint = table.get(pointer);

            if (codePoint == null) {
                return Result.Error(INT_NULL);
            }

            return Result.Token(codePoint);
        }
    }
}
