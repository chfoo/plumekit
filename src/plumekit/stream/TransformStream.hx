package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import plumekit.stream.StreamException.EndOfFileException;


class TransformStream implements Source {
    public var readTimeout(get, set):Float;
    public var source(default, null):Source;
    public var transformer(default, null):Transformer;

    var chunkSize:Int = 8192;
    var transformedBytes:Bytes;
    var transformedPosition:Int;
    var transformedLength:Int = 0;
    var isEOF = false;

    public function new(source:Source, transformer:Transformer) {
        this.source = source;
        this.transformer = transformer;

        transformer.prepare(source);
    }

    function get_readTimeout():Float {
        return source.readTimeout;
    }

    function set_readTimeout(value:Float):Float {
        return source.readTimeout = value;
    }

    public function close() {
        source.close();
    }

    public function readInto(bytes:Bytes, position:Int, length:Int):Int {
        if (transformedLength == 0 && isEOF) {
            throw new EndOfFileException();
        }

        var minLength = Std.int(Math.min(transformedLength, length));

        bytes.blit(position, transformedBytes, transformedPosition, minLength);
        transformedPosition += minLength;
        transformedLength -= minLength;

        return minLength;
    }

    public function readReady():Task<Source> {
        Debug.assert(source != null);
        return source.readReady().continueWith(sourceReadyCallback);
    }

    function sourceReadyCallback(task:Task<Source>) {
        task.getResult();

        if (transformedLength != 0 || isEOF) {
            return TaskTools.fromResult((this:Source));
        }

        return readAndTransform().continueWith(function (task) {
            task.getResult();

            return TaskTools.fromResult((this:Source));
        });
    }

    function readAndTransform():Task<Int> {
        Debug.assert(transformedLength == 0, transformedLength);

        return transformer.transform(chunkSize).continueWith(function (task) {
            switch (task.getResult()) {
                case Some(bytes):
                    transformedBytes = bytes;
                case None:
                    Debug.assert(!isEOF);
                    transformedBytes = transformer.flush();
                    isEOF = true;
            }

            transformedPosition = 0;
            transformedLength = transformedBytes.length;

            return TaskTools.fromException(transformedLength);
        });
    }
}
