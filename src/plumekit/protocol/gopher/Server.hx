package plumekit.protocol.gopher;

import callnest.Task;
import callnest.VoidReturn;
import plumekit.eventloop.ConnectionServer;
import plumekit.eventloop.EventLoop;
import plumekit.net.Connection;


class Server extends ConnectionServer {
    public function new(?eventLoop:EventLoop) {
        super(processRequest, eventLoop);
    }

    function processRequest(connection:Connection):Task<VoidReturn> {
        var session = newSession(connection);
        return session.process();
    }

    function newSession(connection:Connection):ServerSession {
        return new ServerSession(connection);
    }
}
