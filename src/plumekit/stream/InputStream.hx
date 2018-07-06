package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import haxe.io.Input;


class InputStream implements Source {
    public var readTimeout(get, set):Float;

    var _readTimeout:Float = Math.POSITIVE_INFINITY;
    var input:Input;

    public function new(input:Input) {
        this.input = input;
    }

    function get_readTimeout():Float {
        return _readTimeout;
    }

    function set_readTimeout(value:Float):Float {
        return _readTimeout = value;
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
