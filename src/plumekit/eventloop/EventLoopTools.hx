package plumekit.eventloop;

import haxe.Timer;


class EventLoopTools {
    public static function startTimed(eventLoop:EventLoop, duration:Float) {
        eventLoop.start();

        Timer.delay(function () {
            eventLoop.stop();
        }, Std.int(duration * 1000));
    }
}
