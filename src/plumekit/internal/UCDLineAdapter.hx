package plumekit.internal;

import haxe.ds.Option;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import org.msgpack.MsgPack;
import plumekit.text.unicode.UCDLine;
import resdb.adapter.CursorAdapter;
import resdb.adapter.IntConverter;
import resdb.adapter.TypeConverter;
import resdb.Database;
import resdb.PagePacker;


class UCDLineAdapter {
    static var ucdLineConverter(get, never):UCDLineConverter;
    static var _ucdLineConverter:UCDLineConverter;

    static function get_ucdLineConverter():UCDLineConverter {
        if (_ucdLineConverter == null) {
            _ucdLineConverter = new UCDLineConverter();
        }
        return _ucdLineConverter;
    }

    public static function ucdLineAddRecord(pagePacker:PagePacker, ucdLine:UCDLine) {
        pagePacker.addRecord(
            IntConverter.intToBytes(ucdLine.codePoint),
            ucdLineConverter.toBytes(ucdLine));
    }

    public static function ucdLineGet(database:Database, key:Int):Option<UCDLine> {
        switch database.get(IntConverter.intToBytes(key)) {
            case Some(bytes):
                return Some(ucdLineConverter.fromBytes(bytes));
            case None:
                return None;
        }
    }

    public static function ucdLineCursor(database:Database):CursorAdapter<Int,UCDLine> {
        var intConverter = new IntConverter();

        return new CursorAdapter(database.cursor(), intConverter, ucdLineConverter);
    }
}

typedef SerializedUCDLine = {
    c:Int, // c = code point
    f:Array<String> // f = fields
};

typedef SerializedUCDLineRange = {
    > SerializedUCDLine,
    ec:Null<Int>  // ec = end code point
};


class UCDLineConverter implements TypeConverter<UCDLine> {
    public function new() {
    }

    public function toBytes(input:UCDLine):Bytes {
        return toBytesSimple(input);
    }

    function toBytesSimple(input:UCDLine):Bytes {
        var length = 4 // code point
            + 4 // end code point
            + 1; // field array length

        for (field in input.fields) {
            length += 1 // string length
                + field.length; // assume ASCII string
        }

        var bytes = Bytes.alloc(length);

        bytes.setInt32(0, input.codePoint);

        switch input.endCodePoint {
            case Some(endCodePoint):
                bytes.setInt32(3, endCodePoint);
            case None:
                bytes.setInt32(3, -1);
        }

        bytes.set(7, input.fields.length);
        var offset = 8;

        for (field in input.fields) {
            bytes.set(offset, field.length);
            offset += 1;

            for (charIndex in 0...field.length) {
                bytes.set(offset + charIndex, field.charCodeAt(charIndex));
            }

            offset += field.length;
        }

        return bytes;
    }

    function toBytesMsgPack(input:UCDLine):Bytes {
        switch input.endCodePoint {
            case Some(endCodePoint):
                var serialized:SerializedUCDLineRange = {
                    c: input.codePoint,
                    ec: endCodePoint,
                    f: input.fields
                };
                return MsgPack.encode(serialized);

            case None:
                var serialized:SerializedUCDLine = {
                    c: input.codePoint,
                    f: input.fields
                };
                return MsgPack.encode(serialized);
        }
    }

    public function fromBytes(input:Bytes):UCDLine {
        return fromBytesSimple(input);
    }

    function fromBytesSimple(input:Bytes):UCDLine {
        var ucdLine = new UCDLine();
        ucdLine.codePoint = input.getInt32(0);

        var endCodePoint = input.getInt32(3);

        if (endCodePoint >= 0) {
            ucdLine.endCodePoint = Some(endCodePoint);
        } else {
            ucdLine.endCodePoint = None;
        }

        var numFields = input.get(7);
        var offset = 8;

        for (fieldIndex in 0...numFields) {
            var fieldLength = input.get(offset);
            offset += 1;
            var fieldBuf = new StringBuf();

            for (charIndex in 0...fieldLength) {
                fieldBuf.addChar(input.get(offset + charIndex));
            }

            ucdLine.fields.push(fieldBuf.toString());
            offset += fieldLength;
        }

        return ucdLine;
    }

    function fromBytesMsgPack(input:Bytes):UCDLine {
        var parsed:Any = MsgPack.decode(input);
        var doc:DynamicAccess<Any> = parsed;
        var ucdLine = new UCDLine();

        var serialized:SerializedUCDLine = parsed;
        ucdLine.codePoint = serialized.c;
        ucdLine.fields = serialized.f;

        if (doc.exists("ec")) {
            var serialized:SerializedUCDLineRange = parsed;
            ucdLine.endCodePoint = Some(serialized.ec);
        }

        return ucdLine;
    }
}
