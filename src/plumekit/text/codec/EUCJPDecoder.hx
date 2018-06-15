package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;

using plumekit.text.codec.CodecTools;


class EUCJPDecoder implements Handler {
    var indexJIS0208:IMap<Int,Int>;
    var indexJIS0212:IMap<Int,Int>;
    var jis0212Flag = false;
    var eucjpLead = 0;

    public function new() {
        indexJIS0208 = IndexLoader.getPointerToCodePointMap("jis0208");
        indexJIS0212 = IndexLoader.getPointerToCodePointMap("jis0212");
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM && eucjpLead != 0) {
            eucjpLead = 0;
            return Result.Error(CodecTools.INT_NULL);
        } else if (byte == Stream.END_OF_STREAM && eucjpLead == 0) {
            return Result.Finished;
        }

        if (eucjpLead == 0x8E && byte.isInRange(0xA1, 0xDF)) {
            eucjpLead = 0;
            return Result.Token(0xFF61 - 0xA1 + byte);
        } else if (eucjpLead == 0x8F && byte.isInRange(0xA1, 0xFE)) {
            jis0212Flag = true;
            eucjpLead = byte;
            return Result.Continue;
        } else if (eucjpLead != 0x00) {
            return processLeadNotZero(stream, byte);
        }

        if (byte.isASCII()) {
            return Result.Token(byte);
        }

        if (byte == 0x8E || byte == 0x8F || byte.isInRange(0xA1, 0xFE)) {
            eucjpLead = byte;
            return Result.Continue;
        }

        return null;
    }

    function processLeadNotZero(stream:Stream, byte:Int) {
        var lead = eucjpLead;
        eucjpLead = 0;

        var codePoint = CodecTools.INT_NULL;

        if (lead.isInRange(0xA1, 0xFE) && byte.isInRange(0xA1, 0xFE)) {
            var pointer = (lead - 0xA1) * 94 + byte - 0xA1;

            if (!jis0212Flag) {
                if (indexJIS0208.exists(pointer)) {
                    codePoint = indexJIS0208.get(pointer);
                }
            } else {
                if (indexJIS0212.exists(pointer)) {
                    codePoint = indexJIS0212.get(pointer);
                }
            }
        }

        jis0212Flag = false;

        if (codePoint != CodecTools.INT_NULL) {
            return Result.Token(codePoint);
        }

        if (byte.isASCII()) {
            stream.unshift(byte);
        }

        return Result.Error(CodecTools.INT_NULL);
    }

}
