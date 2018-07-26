package plumekit.net;

import callnest.TaskDefaults;
import callnest.TaskSource;
import callnest.Task;
import js.html.WebSocket;
import plumekit.stream.Sink;
import plumekit.stream.Source;

using StringTools;


class WebSocketClientConnection implements Connection {
    public var sink(get, never):Sink;
    public var source(get, never):Source;
    public var connectTimeout(get, set):Float;

    var _connectTimeout:Float = Math.POSITIVE_INFINITY;
    var stream:WebSocketClientStream;
    var webSocket:Null<WebSocket>;
    var connectTaskSource:Null<TaskSource<Connection>>;

    public function new() {
        stream = new WebSocketClientStream();
    }

    function get_sink():Sink {
        return stream;
    }

    function get_source():Source {
        return stream;
    }

    function get_connectTimeout():Float {
        return _connectTimeout;
    }

    function set_connectTimeout(value:Float):Float {
        return _connectTimeout = value;
    }

    public function hostAddress():ConnectionAddress {
        throw new Exception.SystemException("Not supported");
    }

    public function peerAddress():ConnectionAddress {
        throw new Exception.SystemException("Not supported");
    }

    public function close():Void {
        if (webSocket != null) {
            webSocket.close();
        }
    }

    public function connect(hostname:String, port:Int):Task<Connection> {
        return connectWS(hostname, port);
    }

    public function connectWS(hostname:String, port:Int, path:String = "",
            secure:Bool = false, ?protocols:Array<String>) {
        var protocol = secure ? "wss" : "ws";
        path = path.startsWith("/") ? path : '/$path';
        protocols = protocols != null ? protocols : [];

        connectTaskSource = TaskDefaults.newTaskSource();

        webSocket = new WebSocket('$protocol://$hostname:$port$path', protocols);
        webSocket.onopen = openCallback;
        webSocket.onclose = closeCallback;

        return connectTaskSource.task;
    }

    public function bind(hostname:String, port:Int):Void {
        throw new Exception.SystemException("Not supported");
    }

    public function listen(backlog:Int):Void {
        throw new Exception.SystemException("Not supported");
    }

    public function accept():Task<Connection> {
        throw new Exception.SystemException("Not supported");
    }

    function openCallback() {
        stream.attach(webSocket);
        connectTaskSource.setResult(this);
    }

    function closeCallback() {
        connectTaskSource.setException(new NetException("Connection failed"));
    }
}
