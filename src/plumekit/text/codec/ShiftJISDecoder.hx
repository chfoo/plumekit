package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;

using plumekit.text.codec.CodecTools;


class ShiftJISDecoder implements Handler {
    var index:IMap<Int,Int>;
    var shiftJISLead = 0;

    public function new() {
        index = IndexLoader.getPointerToCodePointMap("jis0208");
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM && shiftJISLead != 0) {
            shiftJISLead = 0;
            return Result.Error(CodecTools.INT_NULL);
        } else if (byte == Stream.END_OF_STREAM && shiftJISLead == 0) {
            return Result.Finished;
        } else if (shiftJISLead != 0) {
            return processLeadNotZero(stream, byte);
        }

        if (byte.isASCII() || byte == 0x80) {
            return Result.Token(byte);
        } else if (byte.isInRange(0xA1, 0xDF)) {
            return Result.Token(0xFF61 - 0xA1 + byte);
        } else if (byte.isInRange(0x81, 0x9F) || byte.isInRange(0xE0, 0xFC)) {
            shiftJISLead = byte;
            return Result.Continue;
        }

        return Result.Error(CodecTools.INT_NULL);
    }

    function processLeadNotZero(stream:Stream, byte:Int) {
         var lead = shiftJISLead;
        var pointer = CodecTools.INT_NULL;
        shiftJISLead = 0;

        var offset = byte < 0x7F ? 0x40 : 0x41;
        var leadOffset = lead < 0xA0 ? 0x81 : 0xC1;

        if (byte.isInRange(0x40, 0x7E) || byte.isInRange(0x80, 0xFC)) {
            pointer = (lead - leadOffset) * 188 + byte - offset;
        }

        if (pointer.isInRange(8836, 10715)) {
            return Result.Token(0xE000 - 8836 + pointer);
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
