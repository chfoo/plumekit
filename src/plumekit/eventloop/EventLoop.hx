package plumekit.eventloop;

import plumekit.net.Connection;


interface EventLoop {
    function start():Void;
    function stop():Void;
    function scheduleAt(callback:Void->Void, timestamp:Float):EventHandle;
    function scheduleLater(callback:Void->Void, delay:Float):EventHandle;
    function newConnection():Connection;
}
