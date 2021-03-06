package plumekit.stream;

import callnest.Task;
import haxe.ds.Option;
import haxe.io.Bytes;


interface Reader {
    function close():Void;
    function read(amount:Int):Task<ReadResult<Bytes>>;
    function readOnce(?amount:Int):Task<Option<Bytes>>;
    function readAll():Task<Bytes>;
    function readInto(bytes:Bytes, position:Int, length:Int):Task<ReadIntoResult>;
    function readIntoOnce(bytes:Bytes, position:Int, length:Int):Task<Option<Int>>;
}
