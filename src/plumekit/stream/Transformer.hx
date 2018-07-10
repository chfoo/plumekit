package plumekit.stream;

import haxe.io.Bytes;


interface Transformer {
    function transform(chunk:Bytes):Bytes;
    function flush():Bytes;
}
