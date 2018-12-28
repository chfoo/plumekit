package plumekit.internal;

import resdb.Database;
import resdb.PagePacker;
import resdb.store.ResourceHelper;
import resdb.store.ResourcePageStore;
#if macro
import plumekit.text.unicode.UCDFileParser;
import haxe.macro.Context;
import sys.io.File;
#end

using plumekit.internal.UCDLineAdapter;


class UnicodeResource {
    static inline var DATA_TABLE_NAME = "unicode/UnicodeData";
    static inline var IDNA_TABLE_NAME = "unicode/IdnaMappingTable";
    static inline var DERIVED_JOINING_TYPE_NAME = "unicode/DerivedJoiningType";
    static inline var SCRIPTS_NAME = "unicode/Scripts";

    #if macro
    public static function embedUnicodeData() {
        var path = Context.resolvePath("../data/unicode_character_database/11.0.0/ucd/UnicodeData.txt");
        var parser = new UCDFileParser(File.read(path));

        var packer = new PagePacker({ name: DATA_TABLE_NAME });

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

    public static function embedDerivedJoiningType() {
        var path = Context.resolvePath("../data/unicode_character_database/11.0.0/ucd/extracted/DerivedJoiningType.txt");
        var parser = new UCDFileParser(File.read(path));

        var packer = new PagePacker({ name: DERIVED_JOINING_TYPE_NAME });

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

    public static function embedScripts() {
        var path = Context.resolvePath("../data/unicode_character_database/11.0.0/ucd/Scripts.txt");
        var parser = new UCDFileParser(File.read(path));

        var packer = new PagePacker({ name: SCRIPTS_NAME });

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

    public static function getUnicodeDataTable():Database {
        return ResourcePageStore.getDatabase({name: DATA_TABLE_NAME });
    }

    public static function getIDNAMappingTable():Database {
        return ResourcePageStore.getDatabase({name: IDNA_TABLE_NAME });
    }

    public static function getDerivedJoiningTypeTable():Database {
        return ResourcePageStore.getDatabase({name: DERIVED_JOINING_TYPE_NAME });
    }

    public static function getScriptsTable():Database {
        return ResourcePageStore.getDatabase({name: SCRIPTS_NAME });
    }
}
