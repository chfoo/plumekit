package plumekit.test.url;

import utest.Assert;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.Resource;
import plumekit.url.URL;


class TestURL {
    public function new() {
    }

    @Ignored("WIP")
    public function testParseWPT() {
        var jsonRes = Resource.getString("wpt/urltestdata.json");
        var jsonDoc:Array<Any> = Json.parse(jsonRes);

        for (item in jsonDoc) {
            if (Std.is(item, String)) {
                // Skip comments
                continue;
            }

            var doc:DynamicAccess<Any> = item;

            try {
                runTestURLCase(doc);
            } catch (exception:Any) {
                var input = doc.get("input");
                var base = doc.get("base");

                trace('Test URL=$input base=$base');
                Assert.fail(Std.string(exception));
            }
        }
    }

    function runTestURLCase(doc:DynamicAccess<Any>) {
        var input = doc.get("input");
        var base = doc.get("base");
        var url = new URL(input, base);

        Assert.equals(doc.get("protocol"), url.protocol);
        Assert.equals(doc.get("username"), url.username);
        Assert.equals(doc.get("password"), url.password);
        Assert.equals(doc.get("hostname"), url.hostname);
        Assert.equals(doc.get("port"), url.port);
        Assert.equals(doc.get("pathname"), url.pathname);
        Assert.equals(doc.get("search"), url.search);
        Assert.equals(doc.get("hash"), url.hash);
    }
}
