package plumekit.internal;

import haxe.io.Bytes;
import haxe.ds.Option;
import resdb.adapter.CursorAdapter;
import resdb.adapter.IntConverter;
import resdb.PagePacker;
import resdb.Database;


class IntAdapter {
    public static function intAddRecord(pagePacker:PagePacker, key:Int, value:Int) {
        pagePacker.addRecord(
            IntConverter.intToBytes(key), IntConverter.intToBytes(value));
    }

    public static function intGet(database:Database, key:Int):Option<Bytes> {
        return database.get(IntConverter.intToBytes(key));
    }

    public static function intCursor(database:Database):CursorAdapter<Int,Int> {
        var converter = new IntConverter();
        return new CursorAdapter(database.cursor(), converter, converter);
    }
}
