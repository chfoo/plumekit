package plumekit.test.text.idna;

import utest.Assert;
import plumekit.text.idna.Punycode;


class TestPunycode {
    public function new() {
    }

    public function testDecode() {
        var result = Punycode.decode("ihqwcrb4cv8a8dqg056pqjye");
        Assert.equals(
            "\u{4ED6}\u{4EEC}\u{4E3A}\u{4EC0}\u{4E48}\u{4E0D}\u{8BF4}\u{4E2D}\u{6587}",
            result);
    }

    public function testEncode() {
        var result = Punycode.encode(
            "\u{4ED6}\u{4EEC}\u{4E3A}\u{4EC0}\u{4E48}\u{4E0D}\u{8BF4}\u{4E2D}\u{6587}");
        Assert.equals("ihqwcrb4cv8a8dqg056pqjye", result);
    }
}
