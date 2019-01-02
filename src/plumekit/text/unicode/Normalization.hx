package plumekit.text.unicode;

import plumekit.internal.UnicodeResource;
import resdb.adapter.CursorAdapter;
import resdb.Database;

using plumekit.internal.UCDQuickCheckAdapter;
using unifill.Unifill;


enum QuickCheckValue {
    No;
    Yes;
    Maybe;
}

enum NormalizationForm {
    NFD;
    NFC;
    NFKD;
    NFKC;
}

class Normalization {
    static var isAllowedTable:IsAllowedTable;

    static function initIsAllowedTable() {
        if (isAllowedTable == null) {
            isAllowedTable = new IsAllowedTable();
        }
    }

    // UAX #15 quickCheck
    public static function isNFC(source:String):QuickCheckValue {
        initIsAllowedTable();

        var lastCanonicalClass = 0;
        var result = Yes;

        for (codePoint in source.uIterator()) {
            if (isSupplementaryCodePoint(codePoint)) {
                continue;
            }

            var properties = UnicodeDB.getCharacterProperties(codePoint);
            var canonicalClass = properties.canonicalCombiningClass;

            if (lastCanonicalClass > canonicalClass && canonicalClass != 0) {
                return No;
            }

            var check = isAllowedTable.isAllowed(NFC, codePoint);

            switch check {
                case No:
                    return No;
                case Maybe:
                    result = Maybe;
                default:
                    // pass
            }

            lastCanonicalClass = canonicalClass;
        }

        return result;
    }

    static function isSupplementaryCodePoint(codePoint:Int):Bool {
        return codePoint >= 10000;
    }
}


class IsAllowedTable {
    var database:Database;
    var cursor:CursorAdapter<QuickCheckKey,QuickCheckRecord>;

    public function new() {
    }

    function getCursor() {
        if (cursor == null) {
            database = UnicodeResource.getQuickCheckTable();
            cursor = database.quickCheckCursor();
        }

        return cursor;
    }

    public function isAllowed(form:NormalizationForm, codePoint:Int):QuickCheckValue {
        var cursor = getCursor();

        switch cursor.find({form: form, codePoint: codePoint}) {
            case Some(key):
                // continue
            case None:
                return QuickCheckValue.Yes;
        }

        var record = cursor.value();

        switch record.endCodePoint {
            case Some(endCodepoint):
                if (codePoint <= endCodepoint) {
                    return record.value;
                } else {
                    return QuickCheckValue.Yes;
                }
            case None:
                return record.value;
        }
    }
}
