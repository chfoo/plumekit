package plumekit.url;

import haxe.io.UInt16Array;


enum Host {
    Null;
    Domain(domain:String);
    IPv4Address(address:Int);
    IPv6Address(pieces:UInt16Array);
    OpaqueHost(host:String);
    EmptyHost;
}
