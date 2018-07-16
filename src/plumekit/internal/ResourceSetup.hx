package plumekit.internal;

import haxe.Json;
import haxe.io.Bytes;
import org.msgpack.MsgPack;

#if macro
import haxe.macro.Context;
import sys.io.File;
#end


class ResourceSetup {
    public static inline var ENCODING_ENCODINGS = "encoding/encodings.msgpack";
    public static inline var ENCODING_INDEXES = "encoding/indexes.msgpack";

    #if macro
    public static function initResources() {
        embedEncodingFile("../lib/encoding/encodings.json", ENCODING_ENCODINGS);
        embedEncodingFile("../lib/encoding/indexes.json", ENCODING_INDEXES);
    }

    static function embedEncodingFile(path:String, name:String) {
        var path = Context.resolvePath(path);
        var jsonDoc = Json.parse(File.getContent(path));
        var data = jsonToMsgpack(jsonDoc);
        Context.addResource(name, data);
    }
    #end

    static function jsonToMsgpack(doc:Any):Bytes {
        return MsgPack.encode(doc);
    }
}
