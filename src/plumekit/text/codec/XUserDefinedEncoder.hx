package plumekit.text.codec;

import plumekit.text.codec.Handler;

using plumekit.text.CodePointTools;


class XUserDefinedEncoder implements Handler {
    public function new() {
    }

    public function process(stream:Stream, codePoint:Int):Result {
        if (codePoint == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else if (codePoint.isASCII()) {
            return Result.Token(codePoint);
        } else if (codePoint.isInRange(0xF780, 0xF7FF)) {
            return Result.Token(codePoint - 0xF780 + 0x80);
        } else {
            return Result.Error(codePoint);
        }
    }
}
