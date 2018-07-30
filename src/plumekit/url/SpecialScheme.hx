package plumekit.url;

import commonbox.adt.immutable.Set as ImmutableSet;
import commonbox.adt.immutable.Mapping as ImmutableMap;
import commonbox.ds.AutoMap;
import commonbox.ds.Set;


class SpecialScheme {
    public static var schemes(default, null):ImmutableSet<String> = function () {
        var set = new Set();
        set.add("ftp");
        set.add("file");
        set.add("gopher");
        set.add("http");
        set.add("https");
        set.add("ws");
        set.add("wss");
        return set;
    }();

    public static var defaultPorts(default, null):ImmutableMap<String,Int> = function () {
        var map = new AutoMap<String,Int>();
        map.set("ftp", 21);
        // map.set("file", );
        map.set("gopher", 70);
        map.set("http", 80);
        map.set("https", 443);
        map.set("ws", 80);
        map.set("wss", 443);
        return map;
    }();
}
