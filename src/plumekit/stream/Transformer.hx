package plumekit.stream;

import callnest.Task;
import haxe.ds.Option;
import haxe.io.Bytes;


interface Transformer {
    function prepare(source:Source):Void;
    function transform(amount:Int):Task<Option<Bytes>>;
    function flush():Bytes;
}
