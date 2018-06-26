package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import haxe.io.Output;


class OutputStream implements Sink {
    var output:Output;

    public function new(output:Output) {
        this.output = output;
    }

    public function close():Void {
        output.close();
    }

    public function flush():Void {
        output.flush();
    }

    public function write(bytes:Bytes, position:Int, length:Int):Int {
        return output.writeBytes(bytes, position, length);
    }

    public function writeReady():Task<Sink> {
        return TaskTools.fromResult((this:Sink));
    }
}
