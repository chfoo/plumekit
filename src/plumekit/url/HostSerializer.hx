package plumekit.url;

import plumekit.url.Host;


class HostSerializer {
    public static function serialize(host:Host):String {
        switch host {
            case IPv4Address(address):
                return IPv4Serializer.serialize(address);
            case IPv6Address(pieces):
                var serialized = IPv6Serializer.serialize(pieces);
                return '[$serialized]';
            case Domain(host) | OpaqueHost(host):
                return host;
            case EmptyHost:
                return "";
            default:
                throw "shouldn't reach here";
        }
    }
}
