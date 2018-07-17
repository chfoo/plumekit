package plumekit.text.codec;

import haxe.Constraints.IMap;
import plumekit.text.codec.IndexLoader;
import plumekit.text.CodePointTools.INT_NULL;

using plumekit.text.CodePointTools;


private enum DecoderState {
    ASCII;
    Roman;
    Katakana;
    LeadByte;
    TrailByte;
    EscapeStart;
    Escape;
}


class ISO2022JPDecoder implements Handler {
    var index:IMap<Int,Int>;
    var decoderState:DecoderState = ASCII;
    var decoderOutputState:DecoderState = ASCII;
    var iso2022jpLead = 0;
    var iso2022jpOutputFlag = false;

    public function new() {
        index = IndexLoader.getPointerToCodePointMap("jis0208");
    }

    public function process(stream:Stream, byte:Int):Result {
        switch (decoderState) {
            case ASCII:
                return processASCII(stream, byte);
            case Roman:
                return processRoman(stream, byte);
            case Katakana:
                return processKatakana(stream, byte);
            case LeadByte:
                return processLeadByte(stream, byte);
            case TrailByte:
                return processTrailByte(stream, byte);
            case EscapeStart:
                return processEscapeStart(stream, byte);
            case Escape:
                return processEscape(stream, byte);
        }
    }

    function processASCII(stream:Stream, byte:Int) {
        if (byte == 0x1B) {
            decoderState = EscapeStart;
            return Result.Continue;
        } else if (byte.isInRange(0x00, 0x7F)
                && byte != 0x0E && byte != 0x0F && byte != 0x1B) {
            iso2022jpOutputFlag = false;
            return Result.Token(byte);
        } else if (byte == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else {
            iso2022jpOutputFlag = false;
            return Result.Error(INT_NULL);
        }
    }

    function processRoman(stream:Stream, byte:Int) {
        if (byte == 0x1B) {
            decoderState = EscapeStart;
            return Result.Continue;
        } else if (byte == 0x5C) {
            iso2022jpOutputFlag = false;
            return Result.Token(0x00A5);
        } else if (byte == 0x7E) {
            iso2022jpOutputFlag = false;
            return Result.Token(0x203E);
        } else if (byte.isInRange(0x00, 0x7F)
                && byte != 0x0E && byte != 0x0F && byte != 0x1B
                && byte != 0x5C && byte != 0x7E) {
            iso2022jpOutputFlag = false;
            return Result.Token(byte);
        } else if (byte == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else {
            iso2022jpOutputFlag = false;
            return Result.Error(INT_NULL);
        }
    }

    function processKatakana(stream:Stream, byte:Int) {
        if (byte == 0x1B) {
            decoderState = EscapeStart;
            return Result.Continue;
        } else if (byte.isInRange(0x21, 0x5F)) {
            iso2022jpOutputFlag = false;
            return Result.Token(0xFF61 - 0x21 + byte);
        } else if (byte == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else {
            iso2022jpOutputFlag = false;
            return Result.Error(INT_NULL);
        }
    }

    function processLeadByte(stream:Stream, byte:Int) {
        if (byte == 0x1B) {
            decoderState = EscapeStart;
            return Result.Continue;
        } else if (byte.isInRange(0x21, 0x7E)) {
            iso2022jpOutputFlag = false;
            iso2022jpLead = byte;
            decoderState = TrailByte;
            return Result.Continue;
        } else if (byte == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else {
            iso2022jpOutputFlag = false;
            return Result.Error(INT_NULL);
        }
    }

    function processTrailByte(stream:Stream, byte:Int) {
        if (byte == 0x1B) {
            decoderState = EscapeStart;
            return Result.Continue;

        } else if (byte.isInRange(0x21, 0x7E)) {
            decoderState = LeadByte;
            var pointer = (iso2022jpLead - 0x21) * 94 + byte - 0x21;
            var codePoint = INT_NULL;

            if (index.exists(pointer)) {
                codePoint = index.get(pointer);
            }

            if (codePoint == INT_NULL) {
                return Result.Error(INT_NULL);
            }

            return Result.Token(codePoint);

        } else if (byte == Stream.END_OF_STREAM) {
            decoderState = LeadByte;
            stream.unshift(byte);

            return Result.Error(INT_NULL);

        } else {
            decoderState = LeadByte;
            return Result.Error(INT_NULL);
        }
    }

    function processEscapeStart(stream:Stream, byte:Int) {
        if (byte == 0x24 || byte == 0x28) {
            iso2022jpLead = byte;
            decoderState = Escape;
            return Result.Continue;
        }

        stream.unshift(byte);

        iso2022jpOutputFlag = false;
        decoderState = decoderOutputState;
        return Result.Error(INT_NULL);
    }

    function processEscape(stream:Stream, byte:Int) {
        var lead = iso2022jpLead;
        iso2022jpLead = 0;
        var state:DecoderState = null;

        if (lead == 0x28) {
            if (byte == 0x42) {
                state = ASCII;
            } else if (byte == 0x4A) {
                state = Roman;
            } else if (byte == 0x49) {
                state = Katakana;
            }
        } else if (lead == 0x24 && (byte == 0x40 || byte == 0x42)) {
            state = LeadByte;
        }

        if (state != null) {
            decoderState = decoderOutputState = state;
            var outputFlag = iso2022jpOutputFlag;
            iso2022jpOutputFlag = true;

            if (!outputFlag) {
                return Result.Continue;
            } else {
                return Result.Error(INT_NULL);
            }
        }

        stream.unshift(byte);
        stream.unshift(lead);

        iso2022jpOutputFlag = false;
        decoderState = decoderOutputState;

        return Result.Error(INT_NULL);
    }
}
