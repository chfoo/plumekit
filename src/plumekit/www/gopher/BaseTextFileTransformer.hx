package plumekit.www.gopher;

import callnest.Task;
import callnest.TaskTools;
import haxe.ds.Option;
import haxe.io.Bytes;
import plumekit.stream.ReadScanResult;
import plumekit.stream.Source;
import plumekit.stream.TextReader;
import plumekit.stream.Transformer;
import plumekit.text.codec.Encoder;
import plumekit.text.codec.Registry;


private enum State {
    Ready;
    LineIncomplete;
}


class BaseTextFileTransformer implements Transformer {
    var reader:TextReader;
    var state:State;
    var encoding:String;
    var encoder:Encoder;
    var isEOF = false;

    public function new(encoding:String = "Windows-1252") {
        this.encoding = encoding;
        state = Ready;
        encoder = Registry.getEncoder(encoding);
    }

    public function prepare(source:Source) {
        reader = new TextReader(source, encoding);
    }

    public function transform(amount:Int):Task<Option<Bytes>> {
        if (isEOF) {
            return TaskTools.fromResult(None);
        }

        return unescapeChunk().continueWith(function (task) {
            var text = task.getResult();
            return TaskTools.fromResult(Some(encoder.encode(text)));
        });
    }

    public function flush():Bytes {
        return Bytes.alloc(0);
    }

    function unescapeChunk():Task<String> {
        return reader.readLine(true).continueWith(unescapeCallback);
    }

    function unescapeCallback(task:Task<ReadScanResult<String>>):Task<String> {
        var endOfLine;
        var line;

        switch (task.getResult()) {
            case ReadScanResult.Success(line_):
                endOfLine = true;
                line = line_;
            case ReadScanResult.OverLimit(line_)
            | ReadScanResult.Incomplete(line_):
                endOfLine = false;
                line = line_;
                isEOF = true;
        }

        switch (state) {
            case Ready:
                line = processStartOfLine(line);

                if (!endOfLine) {
                    state = LineIncomplete;
                }
            case LineIncomplete:
                if (endOfLine) {
                    state = Ready;
                }
        }

        return TaskTools.fromResult(line);
    }

    function processStartOfLine(line:String):String {
        throw "not implemented";
    }
}
