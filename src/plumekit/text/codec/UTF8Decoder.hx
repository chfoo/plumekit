package plumekit.text.codec;

import plumekit.text.CodePointTools.INT_NULL;

using plumekit.text.CodePointTools;


class UTF8Decoder implements Handler {
    var codePoint = 0;
    var bytesSeen = 0;
    var bytesNeeded = 0;
    var lowerBoundary = 0x80;
    var upperBoundary = 0xbf;

    public function new() {
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM && bytesNeeded != 0) {
            bytesNeeded = 0;
            return Result.Error(INT_NULL);
        } else if (byte == Stream.END_OF_STREAM) {
            return Result.Finished;
        }

        if (bytesNeeded == 0) {
            return processZeroBytesNeeded(byte);
        } else if (!(byte.isInRange(lowerBoundary, upperBoundary))) {
            codePoint = bytesNeeded = bytesSeen = 0;
            lowerBoundary = 0x80;
            upperBoundary = 0xbf;
            stream.unshift(byte);

            return Result.Error(INT_NULL);
        }

        lowerBoundary = 0x80;
        upperBoundary = 0xbf;
        codePoint = (codePoint << 6) | (byte & 0x3f);
        bytesSeen += 1;

        if (bytesSeen != bytesNeeded) {
            return Result.Continue;
        }

        var resultCodePoint = codePoint;
        codePoint = bytesNeeded = bytesSeen = 0;

        return Result.Token(resultCodePoint);
    }

    function processZeroBytesNeeded(byte:Int) {
        if (byte.isInRange(0x00, 0x7f)) {
            return Result.Token(byte);
        } else if (byte.isInRange(0xc2, 0xdf)) {
            bytesNeeded = 1;
            codePoint = byte & 0x1f;
        } else if (byte.isInRange(0xe0, 0xef)) {
            if (byte == 0xe0) {
                lowerBoundary = 0xa0;
            } else if (byte == 0xed) {
                upperBoundary = 0x9f;
            }

            bytesNeeded = 2;
            codePoint = byte & 0xf;
        } else if (byte.isInRange(0xf0,  0xf4)) {
            if (byte == 0xf0) {
                lowerBoundary = 0x90;
            } else if (byte == 0xf4) {
                upperBoundary = 0x8f;
            }

            bytesNeeded = 3;
            codePoint = byte & 0x7;
        } else {
            return Result.Error(INT_NULL);
        }

        return Result.Continue;
    }
}
