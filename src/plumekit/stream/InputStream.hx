package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import haxe.io.Input;


class InputStream implements Source {
    var input:Input;

    public function new(input:Input) {
        this.input = input;
    }

    public function close() {
        input.close();
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Int {
        return input.readBytes(bytes, position, length);
    }

    public function readReady():Task<Source> {
        return TaskTools.fromResult((this:Source));
    }
}
