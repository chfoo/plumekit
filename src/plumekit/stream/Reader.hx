package plumekit.stream;

import callnest.Task;
import haxe.io.Bytes;


interface Reader {
    function close():Void;
    function read(amount:Int):Task<ReadResult<Bytes>>;
    function readOnce(?amount:Int):Task<Bytes>;
    function readAll():Task<Bytes>;
    function readInto(bytes:Bytes, position:Int, length:Int):Task<ReadIntoResult>;
    function readIntoOnce(bytes:Bytes, position:Int, length:Int):Task<Int>;
}
