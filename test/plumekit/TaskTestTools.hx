package plumekit;

import plumekit.eventloop.EventLoop;
import utest.Assert;

using plumekit.eventloop.EventLoopTools;


class TaskTestTools {
    public static inline var TEST_TIMEOUT = 10.0;
    public static inline var LOOP_TIMEOUT = 5.0;

    public static function startAsync(?callback:Void->Void, timeout:Float = TEST_TIMEOUT) {
        return Assert.createAsync(callback, Std.int(timeout * 1000));
    }

    public static function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }

    public static function startTimedTest(eventLoop:EventLoop, timeout:Float = LOOP_TIMEOUT) {
        eventLoop.startTimed(timeout);
    }
}
