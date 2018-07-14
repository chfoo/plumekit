package plumekit.www.gopher;

import callnest.Task;
import callnest.VoidReturn;
import plumekit.net.Connection;

using callnest.TaskTools;


class ServerSession {
    var connection:Connection;
    var protocol:ProtocolReaderWriter;

    public function new(connection:Connection) {
        this.connection = connection;
        protocol = new ProtocolReaderWriter(connection.source, connection.sink);
    }

    public function process():Task<VoidReturn> {
        return protocol.readSelector()
            .continueWith(sampleReadSelectorCallback)
            .continueNext(protocol.writeLastLine)
            .thenResult(Nothing);
    }

    function sampleReadSelectorCallback(task:Task<String>):Task<DirectoryEntity> {
        task.getResult();
        var entity = new DirectoryEntity(
            ItemType.Informational,
            "This is a sample server that returns nothing useful.",
            "",
            "(null)", 0);
        return protocol.writeDirectoryEntity(entity);
    }
}
