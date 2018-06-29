package plumekit.stream;

import callnest.Task;
import plumekit.text.codec.Encoder;
import plumekit.text.codec.ErrorMode;
import plumekit.text.codec.Registry;


class TextWriter {
    var streamWriter:StreamWriter;
    var encoder:Encoder;

    public function new(sink:Sink, encoding:String = "utf-8", ?errorMode:ErrorMode) {
        streamWriter = new StreamWriter(sink);
        encoder = Registry.getEncoder(encoding, errorMode);
    }

    public function write(text:String):Task<Int> {
        return streamWriter.write(encoder.encode(text));
    }

    public function flush() {
        streamWriter.flush();
    }

    public function close() {
        streamWriter.close();
    }
}
