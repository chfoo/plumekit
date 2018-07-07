package plumekit.stream;

import haxe.io.Error;
import haxe.io.Eof;
import plumekit.Exception;


class StreamException extends SystemException {
    public static function wrapHaxeException(exception:Any):Any {
        if (Std.is(exception, String)) {
            return new StreamException(exception);
        } else if (Std.is(exception, Eof)) {
            return new EndOfFileException("Eof");
        } else if (Std.is(exception, Error)) {
            switch (exception:Error) {
                case Error.Blocked:
                    return new StreamException("Error.Blocked");
                case Error.Overflow:
                    return new StreamException("Error.Overflow");
                case Error.OutsideBounds:
                    return new StreamException("Error.OutsideBounds");
                case Error.Custom(custom):
                    return new StreamException(Std.string(custom));
            }
        } else {
            return exception;
        }
    }
}


class BufferFullException extends StreamException {
}


class EndOfFileException extends StreamException {
}
