package plumekit.eventloop;


interface EventHandle {
    var isCanceled(get, never):Bool;
    function cancel():Bool;
}
