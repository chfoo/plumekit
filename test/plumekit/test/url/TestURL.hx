package plumekit.test.url;

import plumekit.Exception.ValueException;
import utest.Assert;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.Resource;
import plumekit.url.URL;


class TestURL {
    public function new() {
    }

    public function testParseWPT() {
        var jsonRes = Resource.getString("wpt/urltestdata.json");
        var jsonDoc:Array<Any> = Json.parse(jsonRes);

        for (item in jsonDoc) {
            if (Std.is(item, String)) {
                // Skip comments
                continue;
            }

            var doc:DynamicAccess<Any> = item;

            runTestURLCase(doc);
        }
    }

    function runTestURLCase(doc:DynamicAccess<Any>) {
        var input = doc.get("input");
        var base = doc.get("base");
        var expectedFailure:Bool = doc.exists("failure") ? doc.get("failure") : false;
        var url = null;

        trace('Test URL=$input base=$base Expected failure=$expectedFailure');

        try {
            url = new URL(input, base);
        } catch (exception:ValueException) {
            trace(' (failure)');
        }

        var expectedProtocol = doc.get("protocol");
        var expectedUsername = doc.get("username");
        var expectedPassword = doc.get("password");
        var expectedHostname = doc.get("hostname");
        var expectedPort = doc.get("port");
        var expectedPathname = doc.get("pathname");
        var expectedSearch = doc.get("search");
        var expectedHash = doc.get("hash");

        var expectedString = '$expectedProtocol,$expectedUsername,'
            + '$expectedPassword,$expectedHostname,$expectedPort,'
            + '$expectedPathname,$expectedSearch,$expectedHash';

        Assert.equals(expectedFailure, url == null);

        if (url == null) {
            return;
        }

        var outputString = '${url.protocol},${url.username},${url.password},'
            + '${url.hostname},${url.port},'
            + '${url.pathname},${url.search},${url.hash}';

        trace('  Expected=$expectedString Output=$outputString');
        Assert.equals(expectedString, outputString);
    }
}
