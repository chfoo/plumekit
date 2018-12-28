package plumekit.text.unicode;

import unifill.CodePoint;
import plumekit.internal.UnicodeResource;
import resdb.adapter.CursorAdapter;
import resdb.Database;

using plumekit.internal.UCDLineAdapter;
using unifill.Unifill;
using StringTools;


class UnicodeDB {
    static var table:Table;

    static function initTable() {
        table = new Table(UnicodeResource.getUnicodeDataTable);
    }

    public static function getCharacterProperties(codePoint:Int):CharacterProperties {
        if (table == null) {
            initTable();
        }

        var ucdLine;

        switch table.get(codePoint) {
            case None:
                throw new Exception.ValueException("Not found");
            case Some(ucdLine_):
                ucdLine = ucdLine_;
        }

        var charProp = new CharacterProperties(codePoint);

        charProp.name = ucdLine.fields[0];
        charProp.generalCategory = ucdLine.fields[1];
        charProp.canonicalCombiningClass = Std.parseInt(ucdLine.fields[2]);
        charProp.bidiClass = ucdLine.fields[3];

        if (ucdLine.fields[4].startsWith("<")) {
            var decomposition = splitTypeField(ucdLine.fields[4]);
            charProp.decompositionType = decomposition[0];
            charProp.decompositionMapping = hexListToString(decomposition[1]);
        }

        if (ucdLine.fields[5] != "") {
            charProp.numericType = "Decimal";
            charProp.numericValue = ucdLine.fields[5];
        } else if (ucdLine.fields[6] != "") {
            charProp.numericType = "Digit";
            charProp.numericValue = ucdLine.fields[6];
        } else if (ucdLine.fields[7] != "") {
            charProp.numericType = "Numeric";
            charProp.numericValue = ucdLine.fields[7];
        }

        charProp.bidiMirrored = ucdLine.fields[8] == "Y";
        charProp.simpleUppercaseMapping = hexToString(ucdLine.fields[11]);
        charProp.simpleLowercaseMapping = hexToString(ucdLine.fields[12]);
        charProp.simpleTitlecaseMapping = hexToString(ucdLine.fields[13]);

        return charProp;
    }

    static function splitTypeField(field:String):Array<String> {
        var pattern = ~/<(.*)> (.*)/i;

        var success = pattern.match(field);

        if (!success) {
            throw new Exception.ValueException('Error parsing type on field $field');
        }

        return [pattern.matched(1), pattern.matched(2)];
    }

    static function hexListToString(list:String):String {
        var codePoints = [];

        for (part in list.split(" ")) {
            var codePoint:CodePoint = IntParser.parseInt(part, 16);
            codePoints.push(codePoint);
        }

        return codePoints.uToString();
    }

    static function hexToString(field:String):String {
        if (field != "") {
            return CodePoint.fromInt(IntParser.parseInt(field, 16)).toString();
        } else {
            return "";
        }
    }
}
