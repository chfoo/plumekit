package plumekit;

import haxe.CallStack;
import plumekit.eventloop.EventLoop;
import utest.Assert;

using plumekit.eventloop.EventLoopTools;


class TaskTestTools {
    public static inline var TEST_TIMEOUT = 4.0;
    public static inline var LOOP_TIMEOUT = 3.0;

    public static function startAsync(?callback:Void->Void, timeout:Float = TEST_TIMEOUT) {
        return Assert.createAsync(callback, Std.int(timeout * 1000));
    }

    public static function exceptionHandler(exception:Any) {
        trace('exceptionHandler $exception');
        Assert.fail(exception);

        if (Std.is(exception, haxe.Exception)) {
            var exception_:haxe.Exception = exception;
            trace(CallStack.toString(exception_.stack));
        }

        throw exception;
    }

    public static function startTimedTest(eventLoop:EventLoop, timeout:Float = LOOP_TIMEOUT) {
        eventLoop.startTimed(timeout);
    }
}
