package plumekit.url;

import plumekit.text.CodePointTools.INT_NULL;

using unifill.Unifill;


class StringPointer {
    public var c(get, never):Int;
    public var remaining(get, never):String;
    public var substring(get, never):String;

    var text:String;
    public var index(default, null) = 0;

    public function new(text:String) {
        this.text = text;
    }

    function get_c():Int {
        if (index < text.uLength()) {
            return text.uCharCodeAt(index);
        } else if (index < 0) {
            throw new Exception('Index $index is negative');
        } else {
            return INT_NULL;
        }
    }

    function get_remaining():String {
        return text.uSubstr(index + 1);
    }

    function get_substring():String {
        return text.uSubstr(index);
    }

    public function increment(amount:Int = 1) {
        index += amount;
    }

    public function reset() {
        index = 0;
    }

    public function isEOF():Bool {
        return index >= text.uLength();
    }
}
