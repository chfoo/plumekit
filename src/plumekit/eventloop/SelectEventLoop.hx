package plumekit.eventloop;

import haxe.Timer;
import haxe.MainLoop;
import plumekit.net.SelectDispatcher;


class SelectEventLoop implements EventLoop {
    var dispatcher:SelectDispatcher;
    var running = false;
    var processEvent:MainEvent;

    public function new(?dispatcher:SelectDispatcher) {
        if (dispatcher == null) {
            dispatcher = new SelectDispatcher();
        }

        this.dispatcher = dispatcher;
    }

    public function start():Void {
        if (!running) {
            running = true;

            processEvent = MainLoop.add(dispatcher.processOnce);
        }
    }

    public function stop():Void {
        if (running) {
            running = false;
            processEvent.stop();
        }
    }

    public function scheduleAt(callback:Void->Void, timestamp:Float):EventHandle {
        return scheduleLater(callback, timestamp - Timer.stamp());
    }

    public function scheduleLater(callback:Void->Void, delay:Float):EventHandle {
        var event:MainEvent;

        event = MainLoop.add(function () {
            callback();
            event.stop();
        });

        event.delay(delay);

        return new SelectEventHandle(event);
    }
}


private class SelectEventHandle implements EventHandle {
    public var isCanceled(get, never):Bool;

    var event:MainEvent;
    var canceled = false;

    public function new(event:MainEvent) {
        this.event = event;
    }

    function get_isCanceled():Bool {
        return canceled;
    }

    public function cancel() {
        if (!canceled) {
            event.stop();
            canceled = true;
            return true;
        } else {
            return false;
        }
    }
}
