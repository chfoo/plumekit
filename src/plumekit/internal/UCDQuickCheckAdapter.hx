package plumekit.internal;

import haxe.io.Bytes;
import resdb.adapter.TypeConverter;
import resdb.adapter.CursorAdapter;
import haxe.ds.Option;
import resdb.Database;
import plumekit.text.unicode.UCDLine;
import plumekit.text.unicode.Normalization;
import resdb.PagePacker;

@:structInit
class QuickCheckKey {
    public var form:NormalizationForm;
    public var codePoint:Int;
}

@:structInit
class QuickCheckRecord {
    public var endCodePoint:Option<Int>;
    public var value:QuickCheckValue;
}


class UCDQuickCheckAdapter {
    public static function quickCheckAddRecord(pagePacker:PagePacker, ucdLine:UCDLine) {
        var form;

        switch ucdLine.fields[0] {
            case "NFD_QC":
                form = NormalizationForm.NFD;
            case "NFC_QC":
                form = NormalizationForm.NFC;
            case "NFKD_QC":
                form = NormalizationForm.NFKD;
            case "NFKC_QC":
                form = NormalizationForm.NFKC;
            default:
                return;
        }

        addRecord(pagePacker, form, ucdLine.codePoint, ucdLine.endCodePoint,
            parseCheckCheckValue(ucdLine.fields[1]));
    }

    static function parseCheckCheckValue(value:String):QuickCheckValue {
        switch value {
            case "N":
                return QuickCheckValue.No;
            case "Y":
                return QuickCheckValue.Yes;
            case "M":
                return QuickCheckValue.Maybe;
            default:
                throw "invalid value";
        }
    }


    static function addRecord(pagePacker:PagePacker, form:NormalizationForm,
            codePoint:Int, endCodePoint:Option<Int>, value:QuickCheckValue) {
        pagePacker.addRecord(
            QuickCheckKeyConverter.keyToBytes(
                {form: form, codePoint: codePoint}),
            QuickCheckRecordConverter.recordToBytes(
                {endCodePoint: endCodePoint, value: value})
        );
    }

    public static function quickCheckCursor(database:Database)
            :CursorAdapter<QuickCheckKey,QuickCheckRecord> {
        return new CursorAdapter(
            database.cursor(),
            new QuickCheckKeyConverter(),
            new QuickCheckRecordConverter()
        );
    }
}


class QuickCheckKeyConverter implements TypeConverter<QuickCheckKey> {
    public function new() {
    }

    public static function keyToBytes(key:QuickCheckKey):Bytes {
        var bytes = Bytes.alloc(5);

        switch key.form {
            case NFD:
                bytes.set(0, 1);
            case NFC:
                bytes.set(0, 2);
            case NFKD:
                bytes.set(0, 3);
            case NFKC:
                bytes.set(0, 4);
        }

        bytes.set(1, (key.codePoint) >> 24 & 0xff);
        bytes.set(2, (key.codePoint) >> 16 & 0xff);
        bytes.set(3, (key.codePoint) >> 8 & 0xff);
        bytes.set(4, key.codePoint & 0xff);

        return bytes;
    }

    public static function bytesToKey(bytes:Bytes):QuickCheckKey {
        var form;

        switch bytes.get(0) {
            case 1:
                form = NFD;
            case 2:
                form = NFC;
            case 3:
                form = NFKD;
            case 4:
                form = NFKC;
            default:
                throw "invalid form";
        }

        var codePoint = (bytes.get(1) << 24)
            | (bytes.get(2) << 16)
            | (bytes.get(3) << 8)
            | bytes.get(4);

        return {
            form: form,
            codePoint: codePoint
        };
    }

    public function toBytes(key:QuickCheckKey):Bytes {
        return keyToBytes(key);
    }

    public function fromBytes(bytes:Bytes):QuickCheckKey {
        return bytesToKey(bytes);
    }
}


class QuickCheckRecordConverter implements TypeConverter<QuickCheckRecord> {
    public function new() {
    }

    public static function recordToBytes(record:QuickCheckRecord):Bytes {
        var bytes = Bytes.alloc(5);

        switch record.endCodePoint {
            case Some(codePoint):
                bytes.setInt32(0, codePoint);
            case None:
                bytes.setInt32(0, -1);
        }

        switch record.value {
            case No:
                bytes.set(4, "N".code);
            case Yes:
                bytes.set(4, "Y".code);
            case Maybe:
                bytes.set(4, "M".code);
        }

        return bytes;
    }

    public static function bytesToRecord(bytes:Bytes):QuickCheckRecord {
        var endCodePoint;

        if (bytes.getInt32(0) == -1) {
            endCodePoint = None;
        } else {
            endCodePoint = Some(bytes.getInt32(0));
        }

        var value;

        switch bytes.get(4) {
            case "N".code:
                value = No;
            case "Y".code:
                value = Yes;
            case "M".code:
                value = Maybe;
            default:
                throw "invalid value";
        }

        return {
            endCodePoint: endCodePoint,
            value: value
        };
    }

    public function toBytes(record:QuickCheckRecord):Bytes {
        return recordToBytes(record);
    }

    public function fromBytes(bytes:Bytes):QuickCheckRecord {
        return bytesToRecord(bytes);
    }
}
