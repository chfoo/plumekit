package plumekit.text.unicode;

import plumekit.internal.UnicodeResource;


class ScriptsTable {
    static var table:Table;
    static inline var DEFAULT = "Unknown";

    static function initTable() {
        table = new Table(UnicodeResource.getScriptsTable);
    }

    public static function get(codePoint:Int):String {
        if (table == null) {
            initTable();
        }

        switch table.get(codePoint) {
            case Some(ucdLine):
                return ucdLine.fields[0];
            case None:
                return DEFAULT;
        }
    }
}
