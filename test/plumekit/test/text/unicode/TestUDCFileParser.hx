package plumekit.test.text.unicode;

import haxe.ds.Option;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import plumekit.text.unicode.UCDFileParser;
import utest.Assert;


class TestUDCFileParser {
    public function new() {
    }

    public function test() {
        var lines = "# Comment\n"
            + "0020; abc # comment\n"
            + "0021..0025; abc; ;; 123\n"
            + "0060;<Something, First>;abc\n"
            + "007f;<Something, Last>;abc\n";

        var input = new BytesInput(Bytes.ofString(lines));
        var parser = new UCDFileParser(input);

        var lines = [];

        while (true) {
            switch parser.getLine() {
                case Some(line):
                    lines.push(line);
                case None:
                    break;
            }
        }

        Assert.equals(3, lines.length);

        Assert.equals(0x20, lines[0].codePoint);
        Assert.same(None, lines[0].endCodePoint);
        Assert.same(["abc"], lines[0].fields);

        Assert.equals(0x21, lines[1].codePoint);
        Assert.same(Some(0x25), lines[1].endCodePoint);
        Assert.same(["abc", "", "", "123"], lines[1].fields);

        Assert.equals(0x60, lines[2].codePoint);
        Assert.same(Some(0x7f), lines[2].endCodePoint);
        Assert.same(["<Something, First>", "abc"], lines[2].fields);
    }
}
