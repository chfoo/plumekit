package plumekit.protocol.gopher;

import plumekit.stream.Source;
import callnest.TaskTools;
import callnest.Task;
import plumekit.net.Connection;


class ClientSession {
    var connection:Connection;
    var protocol:ProtocolReaderWriter;
    var host:String;
    var port:Int;

    public function new(connection:Connection, host:String, port:Int) {
        this.connection = connection;
        this.host = host;
        this.port = port;
        protocol = new ProtocolReaderWriter(connection.source, connection.sink);
    }

    function startRequest(selector:String):Task<String> {
        return connection.connect(host, port)
            .continueWith(function (task) {
                task.getResult();

                protocol = new ProtocolReaderWriter(connection.source, connection.sink);

                return protocol.writeSelector(selector);
            });
    }

    public function requestMenu(selector:String):Task<MenuResponse> {
        return startRequest(selector).continueWith(function (task) {
            task.getResult();
            var menuResponse = new MenuResponse(protocol);

            return TaskTools.fromResult(menuResponse);
        });
    }

    public function requestFile(selector:String, textMode:Bool = false):Task<Source> {
        return startRequest(selector).continueWith(function (task) {
            task.getResult();
            return TaskTools.fromResult(protocol.getFile(textMode));
        });
    }
}
