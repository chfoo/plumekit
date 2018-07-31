package plumekit.text.idna;

import plumekit.internal.UnicodeResource;
import plumekit.text.unicode.UCDLine;
import resdb.adapter.CursorAdapter;
import resdb.Database;

using plumekit.internal.UCDLineAdapter;


enum MappingTableStatus {
    Valid;
    Ignored;
    Mapped(mapping:Array<Int>);
    Deviation(mapping:Array<Int>);
    Disallowed;
}


class MappingTable {
    var useSTD3ASCIIRules:Bool;
    var database:Database;
    var cursor:CursorAdapter<Int,UCDLine>;

    public function new(useSTD3ASCIIRules:Bool) {
        this.useSTD3ASCIIRules = useSTD3ASCIIRules;
        database = UnicodeResource.getIDNAMappingTable();
        cursor = database.ucdLineCursor();
    }

    public function get(codePoint:Int):MappingTableStatus {
        switch cursor.find(codePoint) {
            case None:
                throw new Exception("Couldn't get data for code point");
            default:
                // pass
        }

        var ucdLine = cursor.value();
        var statusStr = ucdLine.fields[0];

        switch statusStr {
            case "valid":
                return Valid;
            case "ignored":
                return Ignored;
            case "mapped":
                return Mapped(parseHexList(ucdLine.fields[1]));
            case "deviation":
                return Deviation(parseHexList(ucdLine.fields[1]));
            case "disallowed":
                return Disallowed;
            case "disallowed_STD3_valid":
                if (useSTD3ASCIIRules) {
                    return Disallowed;
                } else {
                    return Valid;
                }
            case "disallowed_STD3_mapped":
                if (useSTD3ASCIIRules) {
                    return Disallowed;
                } else {
                    return Mapped(parseHexList(ucdLine.fields[1]));
                }
            default:
                throw new Exception('Unknown status $statusStr');
        }
    }

    function parseHexList(field:String):Array<Int> {
        var parts = field.split(" ");
        var codePoints = [];

        for (part in parts) {
            codePoints.push(IntParser.parseInt(part, 16));
        }

        return codePoints;
    }
}
