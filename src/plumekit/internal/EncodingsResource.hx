package plumekit.internal;

import haxe.Constraints.IMap;
import haxe.io.Bytes;
import haxe.Json;
import haxe.Resource;
import org.msgpack.MsgPack;
import resdb.Database;
import resdb.PagePacker;
import resdb.ResourceHelper;

#if macro
import haxe.macro.Context;
import sys.io.File;
#end

using StringTools;
using plumekit.internal.IntAdapter;


class EncodingsResource {
    static inline var ENCODINGS_NAME = "encoding/encodings.msgpack";
    static inline var INDEXES_PREFIX = "encoding/indexes/";

    #if macro
    public static function embedEncodings() {
        var path = Context.resolvePath("../lib/encoding/encodings.json");
        var jsonDoc = Json.parse(File.getContent(path));
        var data = MsgPack.encode(jsonDoc);
        Context.addResource(ENCODINGS_NAME, data);
    }

    public static function embedIndexes() {
        var path = Context.resolvePath("../lib/encoding/indexes.json");
        var jsonDoc:IMap<String,Any> = Json.parse(File.getContent(path));

        for (encodingName in Reflect.fields(jsonDoc)) {
            var data:Any = Reflect.field(jsonDoc, encodingName);

            if (encodingName.endsWith("-ranges")) {
                embedIndexRanges(encodingName, data);
            } else {
                embedIndex(encodingName, data);
            }
        }
    }

    static function embedIndex(name:String, codePoints:Array<Int>) {
        var packer = new PagePacker({ name: '$INDEXES_PREFIX/$name' });

        for (pointer in 0...codePoints.length) {
            var codePoint = codePoints[pointer];

            if (codePoint != null) {
                packer.intAddRecord(pointer, codePoint);
            }
        }

        ResourceHelper.addResource(packer);
    }

    static function embedIndexRanges(name, ranges:Array<Array<Int>>) {
        var packer = new PagePacker({ name: '$INDEXES_PREFIX/$name' });

        for (index in 0...ranges.length) {
            var pointer = ranges[index][0];
            var codePoint = ranges[index][1];

            packer.intAddRecord(pointer, codePoint);
        }

        ResourceHelper.addResource(packer);
    }
    #end

    public static function getEncodings():Any {
        var data = Resource.getBytes(ENCODINGS_NAME);
        Debug.assert(data != null);
        return MsgPack.decode(data);
    }

    public static function getIndex(encodingName:String):Database {
        return ResourceHelper.getDatabase(
            {name: '$INDEXES_PREFIX/$encodingName' });
    }
}
