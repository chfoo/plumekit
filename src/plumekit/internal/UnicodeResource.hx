package plumekit.internal;

import plumekit.text.unicode.Normalization.NormalizationForm;
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
using plumekit.internal.UCDQuickCheckAdapter;


class UnicodeResource {
    static inline var DATA_TABLE_NAME = "unicode/UnicodeData";
    static inline var IDNA_TABLE_NAME = "unicode/IdnaMappingTable";
    static inline var DERIVED_JOINING_TYPE_NAME = "unicode/DerivedJoiningType";
    static inline var SCRIPTS_NAME = "unicode/Scripts";
    static inline var QUICK_CHECK_NAME = "unicode/NormalizationProps/QuickCheck";

    #if macro
    static function embedTable(sourceDataPath:String, tableName:String) {
        var path = Context.resolvePath(sourceDataPath);
        var parser = new UCDFileParser(File.read(path));
        var packer = new PagePacker({ name: tableName });

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

    public static function embedUnicodeData() {
        embedTable("../data/unicode_character_database/11.0.0/ucd/UnicodeData.txt", DATA_TABLE_NAME);
    }

    public static function embedIDNA() {
        embedTable("../data/unicode_character_database/idna/11.0.0/IdnaMappingTable.txt", IDNA_TABLE_NAME);
    }

    public static function embedDerivedJoiningType() {
        embedTable("../data/unicode_character_database/11.0.0/ucd/extracted/DerivedJoiningType.txt", DERIVED_JOINING_TYPE_NAME);
    }

    public static function embedScripts() {
        embedTable("../data/unicode_character_database/11.0.0/ucd/Scripts.txt", SCRIPTS_NAME);
    }

    public static function embedQuickCheck() {
        var path = Context.resolvePath("../data/unicode_character_database/11.0.0/ucd/DerivedNormalizationProps.txt");
        var parser = new UCDFileParser(File.read(path));
        var packer = new PagePacker({ name: QUICK_CHECK_NAME });

        while (true) {
            switch parser.getLine() {
                case Some(ucdLine):
                    packer.quickCheckAddRecord(ucdLine);
                case None:
                    break;
            }
        }

        ResourceHelper.addResource(packer);
    }
    #end

    static function getTable(name:String):Database {
        return ResourcePageStore.getDatabase({name: name });
    }

    public static function getUnicodeDataTable():Database {
        return getTable(DATA_TABLE_NAME);
    }

    public static function getIDNAMappingTable():Database {
        return getTable(IDNA_TABLE_NAME);
    }

    public static function getDerivedJoiningTypeTable():Database {
        return getTable(DERIVED_JOINING_TYPE_NAME);
    }

    public static function getScriptsTable():Database {
        return getTable(SCRIPTS_NAME);
    }

    public static function getQuickCheckTable():Database {
        return getTable(QUICK_CHECK_NAME);
    }
}
