package plumekit.text.codec;

import haxe.io.Bytes;


interface Encoder {
    function encode(text:String):Bytes;
}
