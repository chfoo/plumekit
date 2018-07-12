package plumekit.net;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Eof;
import plumekit.stream.Sink;
import plumekit.stream.Source;
import sys.net.Host;
import sys.net.Socket;

using plumekit.net.AddressTools;


class SelectConnection implements Connection {
    public var sink(get, never):Sink;
    public var source(get, never):Source;
    public var connectTimeout(get, set):Float;

    var _connectTimeout:Float = Math.POSITIVE_INFINITY;
    var socket:Socket;
    var stream:SelectSocketStream;
    var dispatcher:Null<SelectDispatcher>;

    public function new(?socket:Socket, ?dispatcher:SelectDispatcher) {
        this.socket = socket = socket != null ? socket : new Socket();
        this.dispatcher = dispatcher;
        stream = new SelectSocketStream(socket, dispatcher);

        socket.setFastSend(true);
        socket.setBlocking(false);
    }

    function get_connectTimeout():Float {
        return _connectTimeout;
    }

    function set_connectTimeout(value:Float):Float {
        return _connectTimeout = value;
    }

    function get_sink():Sink {
        return stream;
    }

    function get_source():Source {
        return stream;
    }

    public function hostAddress():ConnectionAddress {
        return socket.getHostAddress();
    }

    public function peerAddress():ConnectionAddress {
        return socket.getPeerAddress();
    }

    public function close() {
        dispatcher.closeSocket(socket);
    }

    public function connect(hostname:String, port:Int):Task<Connection> {
        var oldWriteTimeout = stream.writeTimeout;
        stream.writeTimeout = connectTimeout;
        var host = new Host(hostname);

        // Non-blocking, should return immediately
        socket.connect(host, port);

        return stream.writeReady().continueWith(function (task) {
            try {
                socket.connect(host, port);
            } catch (exception:Any) {
                throw NetException.wrapHaxeException(exception);
            }

            stream.writeTimeout = oldWriteTimeout;
            task.getResult();

            return TaskTools.fromResult((this:Connection));
        });
    }

    public function bind(hostname:String, port:Int):Void {
        socket.bind(new Host(hostname), port);
    }

    public function listen(backlog:Int):Void {
        socket.listen(backlog);
    }

    public function accept():Task<Connection> {
        var oldReadTimeout = stream.readTimeout;
        stream.readTimeout = connectTimeout;

        return stream.readReady().continueWith(function (task) {
            stream.readTimeout = oldReadTimeout;
            task.getResult();

            var childSocket;

            try {
                childSocket = socket.accept();
            } catch (exception:Eof) {
                // Race condition where client closes connection
                return accept();
            }

            var childConnection = new SelectConnection(childSocket, dispatcher);

            return TaskTools.fromResult((childConnection:Connection));
        });
    }
}
