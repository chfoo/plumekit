package plumekit.stream;

import callnest.Task;
import haxe.io.Bytes;


interface Source {
    var readTimeout(get, set):Float;

    function close():Void;
    function readInto(bytes:Bytes, position:Int, length:Int):Int;
    function readReady():Task<Source>;
}
