package plumekit.url;

import haxe.ds.Option;
import commonbox.ds.ArrayList;
import plumekit.url.BasicURLParser;

using StringTools;


class URL {
    public var protocol(get, set):String;
    public var username(get, set):String;
    public var password(get, set):String;
    public var host(get, set):String;
    public var hostname(get, set):String;
    public var port(get, set):String;
    public var pathname(get, set):String;
    public var search(get, set):String;
    public var searchParams(default, null):URLSearchParams;
    public var hash(get, set):String;

    var urlRecord:URLRecord;

    public function new(url:String, ?base:String) {
        searchParams = new URLSearchParams();
        var baseRecord = null;

        if (base != null) {
            var baseParser = new BasicURLParser(base);
            baseRecord = runParser(baseParser);
        }

        var parser = new BasicURLParser(url, baseRecord);

        switch parser.parse() {
            case Failure:
                throw new Exception.ValueException();
            case Result(urlRecord_):
                urlRecord = urlRecord_;
        }
    }

    function get_protocol():String {
        return '${urlRecord.scheme}:';
    }

    function set_protocol(value:String):String {
        reparse(value, SchemeStartState);
        return get_protocol();
    }

    function get_username():String {
        return urlRecord.username;
    }

    function set_username(value:String):String {
        if (urlRecord.cannotHaveAUsernamePasswordPort()) {
            return urlRecord.username;
        }

        urlRecord.username = value;

        return value;
    }

    function get_password():String {
        return urlRecord.password;
    }

    function set_password(value:String):String {
        if (urlRecord.cannotHaveAUsernamePasswordPort()) {
            return urlRecord.password;
        }

        urlRecord.password = value;

        return value;
    }

    function get_host():String {
        if (urlRecord.host == Host.Null) {
            return "";
        }

        switch urlRecord.port {
            case None:
                return HostSerializer.serialize(urlRecord.host);
            case Some(port):
                var hostSerialized = HostSerializer.serialize(urlRecord.host);
                var portSerialized = Std.string(port);

                return '$hostSerialized:$portSerialized';
        }
    }

    function set_host(value:String):String {
        if (urlRecord.cannotBeABaseURL) {
            return get_host();
        }

        reparse(value, HostState);

        return get_host();
    }

    function get_hostname():String {
        switch urlRecord.host {
            case Host.Null:
                return "";
            default:
                return HostSerializer.serialize(urlRecord.host);
        }
    }

    function set_hostname(value:String):String {
        if (urlRecord.cannotBeABaseURL) {
            return get_hostname();
        }

        reparse(value, HostnameState);

        return get_hostname();
    }

    function get_port():String {
        switch urlRecord.port {
            case None:
                return "";
            case Some(port_):
                return Std.string(port_);
        }
    }

    function set_port(value:String):String {
        if (urlRecord.cannotHaveAUsernamePasswordPort()) {
            return get_port();
        }

        if (value == "") {
            urlRecord.port = None;
        } else {
            reparse(value, PortState);
        }

        return get_port();
    }

    function get_pathname():String {
        if (urlRecord.cannotBeABaseURL) {
            return urlRecord.path.get(0);
        }

        if (urlRecord.path.isEmpty()) {
            return "";
        }

        var buf = new StringBuf();

        for (part in urlRecord.path) {
            buf.add("/");
            buf.add(part);
        }

        return buf.toString();
    }

    function set_pathname(value:String):String {
        if (urlRecord.cannotBeABaseURL) {
            return get_pathname();
        }

        urlRecord.path.clear();

        reparse(value, PathStartState);

        return get_pathname();
    }

    function get_search():String {
        switch urlRecord.query {
            case None:
                return "";
            case Some(query):
                if (query == "") {
                    return "";
                } else {
                    return '?$query';
                }
        }
    }

    function set_search(value:String):String {
        if (value == "") {
            urlRecord.query = None;
            return get_search();
        }

        if (value.startsWith("?")) {
            value = value.substr(1);
        }

        urlRecord.query = Some("");

        reparse(value, QueryState);

        return get_search();
    }

    function get_hash():String {
        switch urlRecord.fragment {
            case None:
                return "";
            case Some(fragment):
                if (fragment == "") {
                    return "";
                }

                return '#${urlRecord.fragment}';
        }
    }

    function set_hash(value:String):String {
        if (value == "") {
            urlRecord.fragment = Some("");
            return "";
        }

        if (value.startsWith("#")) {
            value = value.substr(1);
        }

        urlRecord.fragment = Some("");

        reparse(value, FragmentState);

        return get_hash();
    }

    function reparse(value:String, state:BasicURLParserState) {
        var parser = new BasicURLParser(value, urlRecord, HostState);
        urlRecord = runParser(parser);
    }

    static function runParser(parser:BasicURLParser):URLRecord {
        switch parser.parse() {
            case Result(record):
                return record;
            case Failure:
                throw new Exception.ValueException();
        }
    }

    public function toString():String {
        return URLSerializer.serialize(urlRecord);
    }

    public function equals(other:URL, excludeFragments:Bool = false):Bool {
        var serializedA = URLSerializer.serialize(urlRecord, excludeFragments);
        var serializedB = URLSerializer.serialize(other.urlRecord, excludeFragments);

        return serializedA == serializedB;
    }
}


class URLSearchParams {
    var list:ArrayList<NameValuePair>;

    public function new() {
        list = new ArrayList();
    }

    public function append(name:String, value:String) {
        list.push({name: name, value: value});

        throw "not implemented";
    }

    public function delete(name:String) {
        throw "not implemented";
    }

    public function get(name:String):Option<String> {
        throw "not implemented";
    }

    public function getAll(name:String):ArrayList<String> {
        throw "not implemented";
    }

    public function has(name:String):Bool {
        throw "not implemented";
    }

    public function set(name:String, value:String) {
        throw "not implemented";
    }

    public function sort() {
        throw "not implemented";
    }

    public function iterator() {
        return list.iterator();
    }

    public function toString():String {
        throw "not implemented";
    }
}
