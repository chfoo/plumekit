package plumekit.text.unicode;

import plumekit.internal.UnicodeResource;


class JoiningTypeTable {
    static var table:Table;
    static inline var DEFAULT = "U";

    static function initTable() {
        table = new Table(UnicodeResource.getDerivedJoiningTypeTable);
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
