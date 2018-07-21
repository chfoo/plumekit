package plumekit.url;

import plumekit.text.CodePointTools.INT_NULL;

using unifill.Unifill;


class StringPointer {
    public var c(get, never):Int;
    public var remaining(get, never):String;

    var text:String;
    var index = 0;

    public function new(text:String) {
        this.text = text;
    }

    function get_c():Int {
        if (index >= 0 && index < text.length) {
            return text.uCharCodeAt(index);
        } else {
            return INT_NULL;
        }
    }

    function get_remaining():String {
        return text.uSubstr(index + 1);
    }

    public function increment(amount:Int = 1) {
        index += amount;
    }

    public function reset() {
        index = 0;
    }
}
