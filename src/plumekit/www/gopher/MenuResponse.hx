package plumekit.www.gopher;

import callnest.Task;
import haxe.ds.Option;


class MenuResponse {
    var protocol:ProtocolReaderWriter;

    public function new(protocol:ProtocolReaderWriter) {
        this.protocol = protocol;
    }

    public function next():Task<Option<DirectoryEntity>> {
        return protocol.readDirectoryEntity();
    }
}
