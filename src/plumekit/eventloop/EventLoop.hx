package plumekit.eventloop;


interface EventLoop {
    function start():Void;
    function stop():Void;
    function scheduleAt(callback:Void->Void, timestamp:Float):EventHandle;
    function scheduleLater(callback:Void->Void, delay:Float):EventHandle;
}
