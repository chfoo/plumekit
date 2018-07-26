package plumekit.test.net;

import plumekit.net.Connection;
import plumekit.eventloop.EventLoop;
import plumekit.eventloop.SelectEventLoop;
import plumekit.net.SelectDispatcher;
import plumekit.test.net.cases.ConnectAcceptTestCase;
import plumekit.test.net.cases.EchoReadWriteTestCase;


class SelectConnectAcceptTestCase extends ConnectAcceptTestCase {
    override function newEventLoop():EventLoop {
        var dispatcher = new SelectDispatcher();
        var eventLoop = new SelectEventLoop(dispatcher);

        return eventLoop;
    }
}

class SelectReadWriteTestCase extends SysEchoReadWriteTestCase {
    override function newEventLoop():EventLoop {
        var dispatcher = new SelectDispatcher();
        eventLoop = new SelectEventLoop(dispatcher);

        return eventLoop;
    }
}

class TestSelectConnection {
    public function new() {
    }

    public function testConnectAndAccept() {
        new SelectConnectAcceptTestCase().testConnectAndAccept();
    }

    public function testConnectFailure() {
        new SelectConnectAcceptTestCase().testConnectFailure();
    }

    public function testEcho() {
        new SelectReadWriteTestCase().testEcho();
    }
}
