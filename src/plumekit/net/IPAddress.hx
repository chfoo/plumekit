package plumekit.net;

import haxe.io.UInt16Array;


enum IPAddress {
    IPAddress4(ip:Int); // 4 bytes, big-endian order
    IPAddress6(ip:UInt16Array);  // 8 16-bit integer pieces, 16 bytes, big-endian order
    IPAddress6Scoped(ip:UInt16Array, scope:String);
}
