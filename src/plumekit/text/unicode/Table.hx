package plumekit.text.unicode;

import haxe.ds.Option;
import resdb.adapter.CursorAdapter;
import resdb.Database;

using plumekit.internal.UCDLineAdapter;

class Table {
    var databaseFactory:Void->Database;
    var database:Database;
    var cursor:CursorAdapter<Int,UCDLine>;

    public function new(databaseFactory:Void->Database) {
        this.databaseFactory = databaseFactory;
    }

    function getDataCursor():CursorAdapter<Int,UCDLine> {
        if (database == null) {
            database = databaseFactory();
            cursor = database.ucdLineCursor();
        }

        return cursor;
    }

    public function get(codePoint:Int):Option<UCDLine> {
        cursor = getDataCursor();

        switch cursor.find(codePoint) {
            case Some(key):
                // continue
            case None:
                return None;
        }

        var ucdLine = cursor.value();

        switch ucdLine.endCodePoint {
            case Some(endCodepoint):
                if (codePoint <= endCodepoint) {
                    return Some(ucdLine);
                } else {
                    return None;
                }
            case None:
                return Some(ucdLine);
        }
    }
}
