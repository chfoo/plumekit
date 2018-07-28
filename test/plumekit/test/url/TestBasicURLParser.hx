package plumekit.test.url;

import haxe.ds.Option;
import plumekit.url.BasicURLParser;
import plumekit.url.Host;
import utest.Assert;


class TestBasicURLParser {
    public function new() {
    }

    public function testHttp() {
        var parser = new BasicURLParser("http://example.com");
        var result = parser.parse();

        switch result {
            case Failure:
                Assert.fail();
            case Result(url):
                Assert.equals("http", url.scheme);
                Assert.same(Host.Domain("example.com"), url.host);
        }
    }

     public function testPath() {
        var parser = new BasicURLParser("http://example.com/abc/def");
        var result = parser.parse();

        switch result {
            case Failure:
                Assert.fail();
            case Result(url):
                Assert.equals(2, url.path.length);
                Assert.equals("abc", url.path.get(0));
                Assert.equals("def", url.path.get(1));
        }
    }

    public function testPort() {
        var parser = new BasicURLParser("http://example.com:8080");
        var result = parser.parse();

        switch result {
            case Failure:
                Assert.fail();
            case Result(url):
                Assert.same(Some(8080), url.port);
        }
    }

    public function testQuery() {
        var parser = new BasicURLParser("http://example.com/?a=b");
        var result = parser.parse();

        switch result {
            case Failure:
                Assert.fail();
            case Result(url):
                Assert.same(Some("a=b"), url.query);
        }
    }

    public function testFragment() {
        var parser = new BasicURLParser("http://example.com/#abc");
        var result = parser.parse();

        switch result {
            case Failure:
                Assert.fail();
            case Result(url):
                Assert.same(Some("abc"), url.fragment);
        }
    }

    public function testUsernamePassword() {
        var parser = new BasicURLParser("http://user:pass@example.com/");
        var result = parser.parse();

        switch result {
            case Failure:
                Assert.fail();
            case Result(url):
                Assert.equals("user", url.username);
                Assert.equals("pass", url.password);
        }
    }

    public function testFile() {
        var parser = new BasicURLParser("file:c:\\Users\\Example\\Untitled.doc");
        var result = parser.parse();

        switch result {
            case Failure:
                Assert.fail();
            case Result(url):
                Assert.equals("file", url.scheme);
                Assert.equals(4, url.path.length);
        }
    }
}
