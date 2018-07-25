package plumekit.text.codec;

import resdb.Database;
import haxe.Constraints.IMap;
import plumekit.internal.EncodingsResource;

using plumekit.text.CodePointTools;
using plumekit.internal.IntAdapter;


enum IndexLoaderFilter {
    None;
    ShiftJIS;
    Big5;
}


class IndexLoader {
    static var databaseCache:Map<String,Database> = new Map();

    public static function getDatabase(encoding:String):Database {
        if (!databaseCache.exists(encoding)) {
            databaseCache.set(encoding, EncodingsResource.getIndex(encoding));
        }

        return databaseCache.get(encoding);
    }

    public static function getPointerToCodePointMap(encoding:String):IMap<Int,Int> {
        var map = new Map<Int,Int>();
        var database = getDatabase(encoding);
        var cursor = database.intCursor();

        while (true) {
            var pointer = cursor.key();
            var codePoint = cursor.value();

            map.set(pointer, codePoint);

            switch cursor.next() {
                case Some(key): continue;
                case None: break;
            }
        }

        return map;
    }

    public static function getCodePointToPointerMap(encoding:String,
            ?filter:IndexLoaderFilter):IMap<Int,Int> {
        filter = filter != null ? filter : None;
        var map = new Map<Int,Int>();
        var database = getDatabase(encoding);
        var cursor = database.intCursor();

         while (true) {
            var pointer = cursor.key();
            var codePoint = cursor.value();

            if (!isFilterSkip(filter, pointer)
            && (!map.exists(codePoint) || isUseLast(filter, codePoint))) {
                map.set(codePoint, pointer);
            }

            switch cursor.next() {
                case Some(key): continue;
                case None: break;
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
}
