package plumekit.url;

import commonbox.adt.VariableSequence;
import commonbox.ds.ArrayList;
import haxe.ds.Option;

using plumekit.url.ParserTools;


class URLRecord {
    public var scheme:String = "";
    public var username:String = "";
    public var password:String = "";
    public var host:Host = Host.Null;
    public var port:Option<Int> = None;
    public var path:VariableSequence<String>;
    public var query:Option<String> = None;
    public var fragment:Option<String> = None;
    public var cannotBeABaseURL:Bool = false;
    public var object:Any = null;

    public function new() {
        path = new ArrayList();
    }

    public function includesCredentials():Bool {
        return username != "" || password != "";
    }

    public function isSpecial():Bool {
        return SpecialScheme.schemes.contains(scheme);
    }

    public function cannotHaveAUsernamePasswordPort() {
        return host == Null
            || host == EmptyHost
            || cannotBeABaseURL
            || scheme == "file";
    }

    public function shortenPath() {
        if (path.isEmpty()) {
            return;
        }

        if (scheme == "file" && path.length == 1
                && path.get(0).isWindowsDriveLetter()) {
            return;
        }

        path.pop();
    }
}
