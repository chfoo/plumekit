package plumekit.test.net;

import plumekit.net.Connection;
import plumekit.eventloop.EventLoop;
import callnest.Task;
import plumekit.eventloop.BrowserEventLoop;
import haxe.io.Bytes;
import plumekit.net.WebSocketClientConnection;
import plumekit.test.net.cases.EchoReadWriteTestCase;
import utest.Assert;

using callnest.TaskTools;


class WSCEchoReadWriteTestCase extends EchoReadWriteTestCase {
    override function setUpServer() {
        // nothing
    }

    override function tearDownServer() {
        // nothing
    }

    override function newEventLoop():EventLoop {
        return new BrowserEventLoop();
    }

    override function getConnection():Task<Connection> {
        var connection = new WebSocketClientConnection();
        return connection.connectWS("echo.websocket.org", 443, true);
    }
}


class TestWebSocketClientConnection {
    public function new() {
    }

    public function testExternalEcho() {
        new WSCEchoReadWriteTestCase().testEcho();
    }
}
