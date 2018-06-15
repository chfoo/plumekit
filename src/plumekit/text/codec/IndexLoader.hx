package plumekit.text.codec;

import haxe.Constraints.IMap;
import haxe.Resource;
import haxe.Json;

using plumekit.text.codec.CodecTools;


enum IndexLoaderFilter {
    None;
    ShiftJIS;
    Big5;
}


typedef GB18030Range = {
    pointer:Int,
    codePoint:Int
};


class IndexLoader {
    static function loadJson():Any {
        var text = Resource.getString("encoding/indexes.json");
        var doc = Json.parse(text);
        return doc;
    }

    static function getArray(encoding:String):Array<Any> {
        var doc = loadJson();
        var array:Array<Any> = Reflect.field(doc, encoding);
        return array;
    }

    public static function getPointerToCodePointMap(encoding:String):IMap<Int,Int> {
        var map = new Map<Int,Int>();
        var array = getArray(encoding);

        for (index in 0...array.length) {
            var value = array[index];

            if (value != null) {
                var pointer = index;
                var codePoint = cast(value, Int);
                map.set(pointer, codePoint);
            }
        }

        return map;
    }

    public static function getCodePointToPointerMap(encoding:String,
            ?filter:IndexLoaderFilter):IMap<Int,Int> {
        filter = filter != null ? filter : None;
        var map = new Map<Int,Int>();
        var array = getArray(encoding);

        for (index in 0...array.length) {
            var value = array[index];

            if (value != null) {
                var pointer = index;

                if (isFilterSkip(filter, pointer)) {
                    continue;
                }

                var codePoint = cast(value, Int);

                if (!map.exists(codePoint) || isUseLast(filter, codePoint)) {
                    map.set(codePoint, pointer);
                }
            }
        }

        return map;
    }

    static function isFilterSkip(filter:IndexLoaderFilter, pointer:Int):Bool {
        switch (filter) {
            case ShiftJIS:
                if (pointer.isInRange(8272, 8835)) {
                    return true;
                }
            case Big5:
                if (pointer < (0xA1 - 0x81) * 157) {
                    return true;
                }
            default:
                // empty
        }

        return false;
    }

    static function isUseLast(filter:IndexLoaderFilter, codePoint:Int):Bool {
        if (filter != Big5) {
            return false;
        }

        switch (codePoint) {
            case 0x2550 | 0x255E | 0x2561 | 0x256A | 0x5331 | 0x5345:
                return true;
            default:
                return false;
        }
    }

    public static function getGB18030Ranges():Array<GB18030Range> {
        var array:Array<Array<Int>> = cast getArray("gb18030-ranges");

        var newArray = [];

        for (item in array) {
            newArray.push({
                pointer: item[0],
                codePoint: item[1]
            });
        }

        return newArray;
    }
}
