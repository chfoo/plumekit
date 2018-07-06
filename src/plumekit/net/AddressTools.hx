package plumekit.net;

import sys.net.Host;
import sys.net.Socket;

private typedef SocketInfo = {host:Host, port:Int};


class AddressTools {
    public static function getHostAddress(socket:Socket):ConnectionAddress {
        return socketInfoToAddress(socket.host());
    }

    public static function getPeerAddress(socket:Socket):ConnectionAddress {
        return socketInfoToAddress(socket.peer());
    }

    static function socketInfoToAddress(info:SocketInfo):ConnectionAddress {
        return {
            hostname: info.host.host,
            port: info.port,
            ipAddress: parseIPAddress(info.host.toString())
        };
    }

    public static function parseIPAddress(address:String):IPAddress {
        // FIXME:

        return null;
    }
}
