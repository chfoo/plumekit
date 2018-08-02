package plumekit.test.text.unicode;

import utest.Assert;
import plumekit.text.unicode.UnicodeDB;


class TestUnicodeDB {
    public function new() {
    }

    public function testGetCharacterProperties00BC() {
        var prop = UnicodeDB.getCharacterProperties(0x00BC);

        Assert.equals("VULGAR FRACTION ONE QUARTER", prop.name);
        Assert.equals("No", prop.generalCategory);
        Assert.equals(0, prop.canonicalCombiningClass);
        Assert.equals("ON", prop.bidiClass);
        Assert.equals("fraction", prop.decompositionType);
        Assert.equals("1\u{2044}4", prop.decompositionMapping);
        Assert.equals("Numeric", prop.numericType);
        Assert.equals("1/4", prop.numericValue);
        Assert.equals(false, prop.bidiMirrored);
        Assert.equals("", prop.simpleUppercaseMapping);
        Assert.equals("", prop.simpleLowercaseMapping);
        Assert.equals("", prop.simpleTitlecaseMapping);
    }

    public function testGetCharacterProperties10400() {
        var prop = UnicodeDB.getCharacterProperties(0x10400);

        Assert.equals("DESERET CAPITAL LETTER LONG I", prop.name);
        Assert.equals("Lu", prop.generalCategory);
        Assert.equals(0, prop.canonicalCombiningClass);
        Assert.equals("L", prop.bidiClass);
        Assert.equals("", prop.decompositionType);
        Assert.equals("", prop.decompositionMapping);
        Assert.equals("", prop.numericType);
        Assert.equals("", prop.numericValue);
        Assert.equals(false, prop.bidiMirrored);
        Assert.equals("", prop.simpleUppercaseMapping);
        Assert.equals("\u{10428}", prop.simpleLowercaseMapping);
        Assert.equals("", prop.simpleTitlecaseMapping);
    }

    public function testGetCharacterProperties11450() {
        var prop = UnicodeDB.getCharacterProperties(0x11450);

        Assert.equals("NEWA DIGIT ZERO", prop.name);
        Assert.equals("Nd", prop.generalCategory);
        Assert.equals(0, prop.canonicalCombiningClass);
        Assert.equals("L", prop.bidiClass);
        Assert.equals("", prop.decompositionType);
        Assert.equals("", prop.decompositionMapping);
        Assert.equals("Decimal", prop.numericType);
        Assert.equals("0", prop.numericValue);
        Assert.equals(false, prop.bidiMirrored);
        Assert.equals("", prop.simpleUppercaseMapping);
        Assert.equals("", prop.simpleLowercaseMapping);
        Assert.equals("", prop.simpleTitlecaseMapping);
    }
}
