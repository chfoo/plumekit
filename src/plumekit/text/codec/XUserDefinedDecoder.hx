package plumekit.text.codec;

import plumekit.text.codec.Handler;

using plumekit.text.CodePointTools;


class XUserDefinedDecoder implements Handler {
    public function new() {
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else if (byte.isASCII()) {
            return Result.Token(byte);
        } else {
            return Result.Token(0xF780 + byte - 0x80);
        }
    }
}
