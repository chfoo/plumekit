package plumekit.stream;

import callnest.Task;
import haxe.io.Bytes;


interface Writer {
    function close():Void;
    function flush():Void;
    function write(bytes:Bytes, ?position:Int, ?length:Int):Task<Int>;
}
