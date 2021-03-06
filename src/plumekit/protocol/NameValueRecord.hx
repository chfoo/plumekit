package plumekit.protocol;

import haxe.Constraints.IMap;

using Lambda;
using plumekit.text.StringTextTools;


class NameValueRecord implements IMap<String,String> {
    static var parser:NameValueRecordParser;
    var data:Map<String,Array<String>>;

    public function new(?keyValues:IMap<String,String>) {
        data = new Map();

        if (keyValues != null) {
            for (key in keyValues.keys()) {
                set(key, keyValues.get(key));
            }
        }
    }

    function normalizeKey(key:String):String {
        return key.toTitleCase();
    }

    public function get(key:String):Null<String> {
        key = normalizeKey(key);

        if (data.exists(key)) {
            return data.get(key)[0];
        } else {
            return null;
        }
    }

    public function getArray(key:String):Null<Array<String>> {
        key = normalizeKey(key);
        return data.get(key);
    }

    public function set(key:String, value:String) {
        key = normalizeKey(key);
        data.set(key, [value]);
    }

    public function setArray(key:String, values:Array<String>) {
        key = normalizeKey(key);

        if (values.length > 0) {
            data.set(key, values);
        } else {
            data.remove(key);
        }
    }

    public function add(key:String, value:String) {
        key = normalizeKey(key);

        if (!data.exists(key)) {
            data.set(key, []);
        }

        data.get(key).push(value);
    }

    public function exists(key:String):Bool {
        key = normalizeKey(key);
        return data.exists(key);
    }

    public function remove(key:String):Bool {
        key = normalizeKey(key);
        return data.remove(key);
    }

    public function keys():Iterator<String> {
        return data.keys();
    }

    public function iterator():Iterator<String> {
        var list = data.map(function (item) { return item[0]; });
        return list.iterator();
    }

    #if (haxe_ver >= 4)
    public function keyValueIterator():KeyValueIterator<String,String> {
        return new NameValueIterator(data);
    }
    #end

    public function toString():String {
        var buffer = new StringBuf();

        for (key in data.keys()) {
            for (value in data.get(key)) {
                buffer.add(key);
                buffer.add(": ");
                buffer.add(value);
                buffer.add("\r\n");
            }
        }

        return buffer.toString();
    }

    public function copy():IMap<String,String> {
        var newMap = new Map<String,String>();

        for (key in data.keys()) {
            newMap.set(key, data.get(key)[0]);
        }

        return newMap;
    }

    public static function parseString(text:String) {
        if (parser == null) {
            parser = new NameValueRecordParser();
        }

        return parser.parse(text);
    }
}


private class NameValueIterator {
    var data:Map<String,Array<String>>;

    public function new(data:Map<String,Array<String>>) {
        this.data = data;
    }

    public function hasNext():Bool {
        // FIXME:
        throw "Not yet implemented";
    }

    public function next():{key: String, value: String} {
        // FIXME:
        throw "Not yet implemented";
    }
}
