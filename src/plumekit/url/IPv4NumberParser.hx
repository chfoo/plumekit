package plumekit.url;

import haxe.ds.Option;
import plumekit.text.IntParser;
import plumekit.Exception;

using StringTools;

typedef ValidationErrorFlag = { value:Bool };


class IPv4NumberParser {
    public static function parse(input:String,
            validationErrorFlag:ValidationErrorFlag):Option<Int> {
        var r = 10;

        if (input.startsWith("0x") || input.startsWith("0X")) {
            validationErrorFlag.value = true;
            input = input.substr(2);
            r = 16;
        } else if (input.length >= 2 && input.charCodeAt(0) == "0".code) {
            validationErrorFlag.value = true;
            input = input.substr(1);
            r = 8;
        }

        if (input == "") {
            return Some(0);
        }

        try {
            return Some(IntParser.parseInt(input, r));
        } catch (exception:ValueException) {
            return None;
        }
    }
}
