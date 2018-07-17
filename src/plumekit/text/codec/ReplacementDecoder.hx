package plumekit.text.codec;

import plumekit.text.CodePointTools.INT_NULL;


class ReplacementDecoder implements Handler {
    var errorReturned = false;

    public function new() {
    }

    public function process(stream:Stream, byte:Int):Result {
        if (byte == Stream.END_OF_STREAM) {
            return Result.Finished;
        } else if (!errorReturned) {
            errorReturned = true;
            return Result.Error(INT_NULL);
        } else {
            return Result.Finished;
        }
    }
}
