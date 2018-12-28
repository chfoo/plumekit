package plumekit.text.unicode;

import resdb.Database;
import resdb.adapter.CursorAdapter;
import plumekit.internal.UnicodeResource;

using plumekit.internal.UCDLineAdapter;


class JoiningTypeTable {
    static var database:Database;
    static var cursor:CursorAdapter<Int,UCDLine>;
    static inline var DEFAULT = "U";

    static function initDatabase() {
        database = UnicodeResource.getDerivedJoiningTypeTable();
        cursor = database.ucdLineCursor();
    }

    public static function get(codePoint:Int):String {
        if (database == null) {
            initDatabase();
        }

        if (cursor.find(codePoint) == None) {
            return DEFAULT;
        }

        var ucdLine = cursor.value();

        switch ucdLine.endCodePoint {
            case Some(endCodePoint):
                if (codePoint > endCodePoint) {
                    return DEFAULT;
                }
            case None:
                // pass
        }
        return ucdLine.fields[0];
    }
}
