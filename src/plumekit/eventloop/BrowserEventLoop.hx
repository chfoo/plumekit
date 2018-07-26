package plumekit.eventloop;

import haxe.Timer;
import js.Browser;
import plumekit.net.Connection;
import plumekit.net.WebSocketClientConnection;


class BrowserEventLoop implements EventLoop {
    public function new() {
    }

    public function start() {
        // no op
    }

    public function stop() {
        // no op
    }

    public function scheduleAt(callback:Void->Void, timestamp:Float):EventHandle {
        return scheduleLater(callback, timestamp - Timer.stamp());
    }

    public function scheduleLater(callback:Void->Void, delay:Float):EventHandle {
        var timer = Browser.window.setTimeout(callback, Std.int(delay * 1000));

        return new BrowserEventHandle(timer);
    }

    public function newConnection():Connection {
        return new WebSocketClientConnection();
    }
}


private class BrowserEventHandle implements EventHandle {
    public var isCanceled(get, never):Bool;

    var cancelled = false;
    var timer:Int;

    public function new(timer:Int) {
        this.timer = timer;
    }

    function get_isCanceled():Bool {
        return cancelled;
    }

    public function cancel():Bool {
        if (!cancelled) {
            Browser.window.clearTimeout(timer);
            cancelled = true;
            return true;
        } else {
            return false;
        }
    }
}
