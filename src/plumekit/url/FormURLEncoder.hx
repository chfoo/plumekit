package plumekit.url;

import haxe.io.Bytes;


class FormURLEncoder {
    public static function parse(input:Bytes):Array<NameValuePair> {
        throw "not implemented";
    }

    public static function byteSerialize(input:Bytes):String {
        throw "not implemented";
    }

    public static function serialize(tuples:Array<NameValuePair>, ?encodingOverride:String):String {
        throw "not implemented";
    }

    public static function stringParse(input:String):Array<NameValuePair> {
        throw "not implemented";
    }
}
