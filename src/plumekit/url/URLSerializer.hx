package plumekit.url;

import plumekit.url.Host;
import haxe.ds.Option;


class URLSerializer {
    public static function serialize(url:URLRecord, excludeFragment:Bool = false) {
        var output = new StringBuf();

        output.add(url.scheme);
        output.add(":");

        switch url.host {
            case Null:
                if (url.scheme == "file") {
                    output.add("//");
                }
            default:
                processHost(url, output);
        }

        processPath(url, output);
        processQuery(url, output);

        if (!excludeFragment) {
            processFragment(url, output);
        }

        return output.toString();
    }

    static function processHost(url:URLRecord, output:StringBuf) {
        output.add("//");

        if (url.includesCredentials()) {
            output.add(url.username);

            if (url.password != "") {
                output.add(":");
                output.add(url.password);
                output.add("@");
            }
        }

        output.add(HostSerializer.serialize(url.host));

        switch url.port {
            case Some(port):
                output.add(":");
                output.add(Std.string(port));
            default:
                // pass
        }
    }

    static function processPath(url:URLRecord, output:StringBuf) {
        if (url.cannotBeABaseURL) {
            if (!url.path.isEmpty()) {
                output.add(url.path.get(0));
            }
        } else {
            for (part in url.path) {
                output.add("/");
                output.add(part);
            }
        }
    }

    static function processQuery(url:URLRecord, output:StringBuf) {
        switch url.query {
            case Some(query):
                output.add("?");
                output.add(query);
            case None:
                // pass
        }
    }

    static function processFragment(url:URLRecord, output:StringBuf) {
        switch url.fragment {
            case Some(fragment):
                output.add("#");
                output.add(fragment);
            case None:
                // pass
        }
    }
}
