package plumekit.www.gopher;

import callnest.Task;
import callnest.TaskTools;
import plumekit.net.Connection;


class ServerSession {
    var connection:Connection;
    var protocol:ProtocolReaderWriter;

    public function new(connection:Connection) {
        this.connection = connection;
        protocol = new ProtocolReaderWriter(connection.source, connection.sink);
    }

    public function process():Task<Connection> {
        return protocol.readSelector()
            .continueWith(readSelectorCallback)
            .continueWith(function (task) {
                task.getResult();
                return TaskTools.fromResult(connection);
            });
    }

    function readSelectorCallback(task:Task<String>) {
        task.getResult();
        var entity = new DirectoryEntity(
            ItemType.Informational,
            "This is a sample server that returns nothing useful.",
            "",
            "(null)", 0);
        return protocol.writeDirectoryEntity(entity);
    }
}
