package plumekit.text.codec;

import plumekit.text.CodePointTools.INT_NULL;

using plumekit.text.CodePointTools;


class UTF16Decoder implements Handler {
    var utf16LeadByte = INT_NULL;
    var utf16LeadSurrogate = INT_NULL;
    var utf16BEDecoderFlag = false;

    public function new(bigEndian:Bool = false) {
        utf16BEDecoderFlag = bigEndian;
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM
                && (utf16LeadByte != INT_NULL
                || utf16LeadSurrogate != INT_NULL)) {
            utf16LeadByte = utf16LeadSurrogate = INT_NULL;
            return Result.Error(INT_NULL);

        } else if (byte == Stream.END_OF_STREAM
                && utf16LeadByte == INT_NULL
                && utf16LeadSurrogate == INT_NULL) {
            return Result.Finished;

        } else if (utf16LeadByte == INT_NULL) {
            utf16LeadByte = byte;
            return Result.Continue;
        }

        var codeUnit;

        if (utf16BEDecoderFlag) {
            codeUnit = (utf16LeadByte << 8) | byte;
        } else {
            codeUnit = (byte << 8) | utf16LeadByte;
        }

        utf16LeadByte = INT_NULL;

        if (utf16LeadSurrogate != INT_NULL) {
            return processLeadSurrogateNotNull(stream, byte, codeUnit);
        }

        if (codeUnit.isInRange(0xD800, 0xDBFF)) {
            utf16LeadSurrogate = codeUnit;
            return Result.Continue;
        } else if (codeUnit.isInRange(0xDC00, 0xDFFF)) {
            return Result.Error(INT_NULL);
        }

        return Result.Token(codeUnit);
    }

    function processLeadSurrogateNotNull(stream:Stream, byte:Int, codeUnit:Int) {
        var leadSurrogate = utf16LeadSurrogate;
        utf16LeadSurrogate = INT_NULL;

        if (codeUnit.isInRange(0xDC00, 0xDFFF)) {
            var codePoint = 0x10000
                + ((leadSurrogate - 0xD800) << 10)
                + (codeUnit - 0xDC00);
            return Result.Token(codePoint);
        }

        var byte1 = codeUnit >> 8;
        var byte2 = codeUnit & 0xFF;

        if (utf16BEDecoderFlag) {
            stream.unshift(byte2);
            stream.unshift(byte1);
        } else {
            stream.unshift(byte1);
            stream.unshift(byte2);
        }

        return Result.Error(INT_NULL);
    }
}
