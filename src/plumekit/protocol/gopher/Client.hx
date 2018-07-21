package plumekit.protocol.gopher;

import plumekit.eventloop.DefaultEventLoop;
import plumekit.eventloop.EventLoop;
import plumekit.stream.Source;
import callnest.Task;


class Client {
    var eventLoop:EventLoop;

    public function new(?eventLoop:EventLoop) {
        if (eventLoop == null) {
            eventLoop = DefaultEventLoop.instance();
        }

        this.eventLoop = eventLoop;
    }

    public function requestMenu(host:String, port:Int, selector:String):Task<MenuResponse> {
        var session = new ClientSession(eventLoop.newConnection(), host, port);
        return session.requestMenu(selector);
    }

    public function requestFile(host:String, port:Int, selector:String, textMode:Bool):Task<Source> {
        var session = new ClientSession(eventLoop.newConnection(), host, port);

        return session.requestFile(selector, textMode);
    }
}
