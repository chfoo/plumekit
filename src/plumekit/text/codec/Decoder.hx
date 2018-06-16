package plumekit.text.codec;

import haxe.io.Bytes;


interface Decoder {
    function decode(data:Bytes, incremental:Bool = false):String;
    function flush():String;
}
