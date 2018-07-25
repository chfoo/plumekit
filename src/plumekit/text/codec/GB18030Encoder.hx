package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;
import plumekit.text.CodePointTools.INT_NULL;
import resdb.Database;

using plumekit.text.codec.CodecTools;
using plumekit.text.CodePointTools;
using plumekit.internal.IntAdapter;


class GB18030Encoder implements Handler {
    var gbkFlag = false;
    var index:IMap<Int,Int>;
    var rangesDatabase:Database;

    public function new(gbkFlag:Bool = false) {
        this.gbkFlag = gbkFlag;
        index = IndexLoader.getCodePointToPointerMap("gb18030");
        rangesDatabase = IndexLoader.getDatabase("gb18030-ranges");
    }

    public function process(stream:Stream, codePoint:Int):Result {
        if (codePoint == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else if (codePoint.isASCII()) {
            return Result.Token(codePoint);
        } else if (codePoint == 0xE5E5) {
            return Result.Error(codePoint);
        } else if (gbkFlag && codePoint == 0x20AC) {
            return Result.Token(0x80);
        }

        var pointer;

        if (index.exists(codePoint)) {
            pointer = index.get(codePoint);
        } else {
            pointer = INT_NULL;
        }

        if (pointer != INT_NULL) {
            var lead = pointer.div(190) + 0x81;
            var trail = pointer % 190;
            var offset = trail < 0x3F ? 0x40 : 0x41;

            return Result.Tokens([lead, trail + offset]);
        }

        if (gbkFlag) {
            return Result.Error(codePoint);
        }

        pointer = getIndexRangesPointer(codePoint);
        var byte1 = pointer.div(10 * 126 * 10);
        pointer %= 10 * 126 * 10;
        var byte2 = pointer.div(10 * 126);
        pointer %= 10 * 126;
        var byte3 = pointer.div(10);
        var byte4 = pointer % 10;

        return Result.Tokens([byte1 + 0x81, byte2 + 0x30, byte3 + 0x81, byte4 + 0x30]);
    }

    function getIndexRangesPointer(codePoint:Int):Int {
        if (codePoint == 0xE7C7) {
            return 7457;
        }

        var offset = INT_NULL;
        var pointerOffset = INT_NULL;
        var cursor = rangesDatabase.intCursor();

        while (true) {
            var cursorPointer = cursor.key();
            var cursorCodePoint = cursor.value();

            if (cursorCodePoint <= codePoint) {
                offset = cursorCodePoint;
                pointerOffset = cursorPointer;
            } else {
                break;
            }

            switch cursor.next() {
                case Some(key): continue;
                case None: break;
            }
        }

        return pointerOffset + codePoint - offset;
    }
}
