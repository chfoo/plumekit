package plumekit.test.text;

import plumekit.Exception;
import plumekit.text.IntParser;
import utest.Assert;

using haxe.Int64;


class TestIntParser {
    public function new() {
    }

    public function testParseHex() {
        Assert.equals(0, IntParser.parseInt("0", 16));
        Assert.equals(0, IntParser.parseInt("00", 16));
        Assert.equals(0, IntParser.parseInt("000", 16));
        Assert.equals(1, IntParser.parseInt("1", 16));
        Assert.equals(1, IntParser.parseInt("01", 16));
        Assert.equals(1, IntParser.parseInt("001", 16));
        Assert.equals(201, IntParser.parseInt("C9", 16));
        Assert.equals(201, IntParser.parseInt("c9", 16));

        Assert.raises(IntParser.parseInt.bind("", 16), ValueException);
        Assert.raises(IntParser.parseInt.bind("-1", 16), ValueException);
        Assert.raises(IntParser.parseInt.bind("G", 16), ValueException);
    }

    public function testParseDecimal() {
        Assert.equals(0, IntParser.parseInt("0", 10));
        Assert.equals(0, IntParser.parseInt("00", 10));
        Assert.equals(0, IntParser.parseInt("000", 10));
        Assert.equals(1, IntParser.parseInt("1", 10));
        Assert.equals(1, IntParser.parseInt("01", 10));
        Assert.equals(1, IntParser.parseInt("001", 10));
        Assert.equals(201, IntParser.parseInt("201", 10));

        Assert.raises(IntParser.parseInt.bind("", 10), ValueException);
        Assert.raises(IntParser.parseInt.bind("-1", 10), ValueException);
        Assert.raises(IntParser.parseInt.bind("A", 10), ValueException);
    }

    public function testParseOctal() {
        Assert.equals(0, IntParser.parseInt("0", 8));
        Assert.equals(0, IntParser.parseInt("00", 8));
        Assert.equals(0, IntParser.parseInt("000", 8));
        Assert.equals(1, IntParser.parseInt("1", 8));
        Assert.equals(1, IntParser.parseInt("01", 8));
        Assert.equals(1, IntParser.parseInt("001", 8));
        Assert.equals(201, IntParser.parseInt("311", 8));

        Assert.raises(IntParser.parseInt.bind("", 8), ValueException);
        Assert.raises(IntParser.parseInt.bind("-1", 8), ValueException);
        Assert.raises(IntParser.parseInt.bind("8", 8), ValueException);
    }

    public function testRange() {
        Assert.equals(0x7fffffff, IntParser.parseInt("7fffffff", 16));
        Assert.raises(IntParser.parseInt.bind("ffffffff", 16), NumericalRangeException);
        Assert.raises(IntParser.parseInt.bind("100000000", 16), NumericalRangeException);
        Assert.equals(Int64.make(0, 0xffffffff).toStr(), IntParser.parseInt64("ffffffff", 16).toStr());
        Assert.raises(IntParser.parseInt64.bind("ffffffffffffffff", 16), NumericalRangeException);
    }
}
