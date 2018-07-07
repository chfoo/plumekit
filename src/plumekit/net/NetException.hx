package plumekit.net;

import haxe.io.Error;
import plumekit.stream.StreamException;


class NetException extends StreamException {
    public static function wrapHaxeException(exception:Any):Any {
        if (Std.is(exception, String)) {
            return new NetException(exception);
        } else if (Std.is(exception, Error)) {
            switch (exception:Error) {
                case Error.Custom(custom):
                    return new NetException(Std.string(custom));
                default:
                    // pass
            }
        }

        return StreamException.wrapHaxeException(exception);
    }
}


class TimeoutException extends NetException {
}
