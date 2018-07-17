package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;
import plumekit.text.CodePointTools.INT_NULL;

using plumekit.text.CodePointTools;


class EUCKRDecoder implements Handler {
    var index:IMap<Int,Int>;
    var euckrLead = 0;

    public function new() {
        index = IndexLoader.getPointerToCodePointMap("euc-kr");
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM && euckrLead != 0) {
            euckrLead = 0;
            return Result.Error(INT_NULL);
        } else if (byte == Stream.END_OF_STREAM && euckrLead == 0) {
            return Result.Finished;
        } else if (euckrLead != 0) {
            return processLeadNotZero(stream, byte);
        }

        if (byte.isASCII()) {
            return Result.Token(byte);
        } else if (byte.isInRange(0x81, 0xFE)) {
            euckrLead = byte;
            return Result.Continue;
        }

        return Result.Error(INT_NULL);
    }

    function processLeadNotZero(stream:Stream, byte:Int) {
        var lead = euckrLead;
        var pointer = INT_NULL;
        euckrLead = 0;

        if (byte.isInRange(0x41, 0xFE)) {
            pointer = (lead - 0x81) * 190 + (byte - 0x41);
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

        stream.unshift(byte);

        return Result.Error(INT_NULL);
    }
}
