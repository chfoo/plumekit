package plumekit.stream;

import callnest.Task;
import haxe.io.Bytes;


interface Sink {
    var writeTimeout(get, set):Float;

    function close():Void;
    function flush():Void;
    function write(bytes:Bytes, position:Int, length:Int):Int;
    function writeReady():Task<Sink>;
}
