package plumekit.net;

import callnest.Task;
import plumekit.stream.Sink;
import plumekit.stream.Source;


interface Connection {
    var sink(get, never):Sink;
    var source(get, never):Source;
    var connectTimeout(get, set):Float;

    function hostAddress():ConnectionAddress;
    function peerAddress():ConnectionAddress;
    function close():Void;
    function connect(hostname:String, port:Int):Task<Connection>;
    function bind(hostname:String, port:Int):Void;
    function listen(backlog:Int):Void;
    function accept():Task<Connection>;
}
