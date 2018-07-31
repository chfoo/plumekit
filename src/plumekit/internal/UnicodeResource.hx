package plumekit.internal;

import resdb.ResourceHelper;
import resdb.Database;
import resdb.PagePacker;
#if macro
import plumekit.text.unicode.UCDFileParser;
import haxe.macro.Context;
import sys.io.File;
#end

using plumekit.internal.UCDLineAdapter;


class UnicodeResource {
    static inline var IDNA_TABLE_NAME = "unicode/IdnaMappingTable";

    #if macro
    public static function embedIDNA() {
        var path = Context.resolvePath("../data/unicode_character_database/idna/11.0.0/IdnaMappingTable.txt");
        var parser = new UCDFileParser(File.read(path));

        var packer = new PagePacker({ name: IDNA_TABLE_NAME });

        while (true) {
            switch parser.getLine() {
                case Some(ucdLine):
                    packer.ucdLineAddRecord(ucdLine);
                case None:
                    break;
            }
        }

        ResourceHelper.addResource(packer);
    }
    #end

    public static function getIDNAMappingTable():Database {
        return ResourceHelper.getDatabase({name: IDNA_TABLE_NAME });
    }
}
