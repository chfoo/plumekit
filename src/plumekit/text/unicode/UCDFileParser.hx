package plumekit.text.unicode;

import haxe.io.Eof;
import haxe.ds.Option;
import haxe.io.Input;
// import plumekit.stream.InputStream;
// import plumekit.stream.TextReader;

using StringTools;


class UCDFileParser {
    // I get a "Constructor is not a function" macro initialization error using
    // TextReader, so we'll just use the builtin Input directly
    // var reader:TextReader;
    var input:Input;

    var eof:Bool = false;

    public function new(input:Input) {
        this.input = input;
        // reader = new TextReader(new InputStream(file));
    }

    public function getLine():Option<UCDLine> {
        if (eof) {
            return None;
        }

        var ucdLine = new UCDLine();
        var multiLineRange = false;

        do {
            if (eof && multiLineRange) {
                throw new Exception("Could not find end range");
            } else if (eof) {
                return None;
            }

            var line = cleanLine(readLine());

            if (line == "") {
                continue;
            }

            var fields = splitFields(line);
            var codePointStr = fields[0];

            if (ucdLine.fields.length == 0) {
                ucdLine.fields = fields.slice(1);
            }

            if (codePointStr.indexOf("..") >= 0) {
                parseCodePointRange(codePointStr, ucdLine);
            } else {
                var codePoint = parseCodePoint(codePointStr);

                if (multiLineRange) {
                    ucdLine.endCodePoint = Some(codePoint);
                    multiLineRange = false;
                } else {
                    ucdLine.codePoint = codePoint;
                    multiLineRange = fields[1].indexOf("First>") >= 0;
                }
            }

        } while (ucdLine.codePoint < 0 || multiLineRange);

        return Some(ucdLine);
    }

    function readLine() {
        try {
            return input.readLine();
        } catch (exception:Eof) {
            eof = true;
            return "";
        }
    }

    // function readLine() {
    //     switch reader.readLine().getResult() {
    //         case Success(line):
    //             return line;
    //         case Incomplete(line):
    //             eof = true;
    //             return line;
    //         case OverLimit(_):
    //             throw new Exception("Line too long");
    //     }
    // }

    function cleanLine(line:String):String {
        var commentIndex = line.indexOf("#");

        if (commentIndex >= 0) {
            line = line.substr(0, commentIndex);
        }

        line = line.trim();

        return line;
    }

    function splitFields(line:String):Array<String> {
        var fields = line.split(";");

        for (index in 0...fields.length) {
            fields[index] = fields[index].trim();
        }

        return fields;
    }

    function parseCodePointRange(field:String, ucdLine:UCDLine) {
        var range = field.split("..");
        ucdLine.codePoint = IntParser.parseInt(range[0], 16);
        ucdLine.endCodePoint = Some(IntParser.parseInt(range[1], 16));
    }

    function parseCodePoint(field:String):Int {
        return IntParser.parseInt(field, 16);
    }
}
