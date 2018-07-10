package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import commonbox.ds.Deque;
import haxe.io.Bytes;
import plumekit.stream.StreamException.EndOfFileException;


class TransformStream implements Source {
    public var readTimeout(get, set):Float;
    public var source(default, null):Source;
    public var transformer(default, null):Transformer;

    var chunkSize:Int = 8192;
    var buffer:Bytes;
    var transformedBuffer:Deque<Int>;
    var isEOF = false;

    public function new(source:Source, transformer:Transformer) {
        this.source = source;
        this.transformer = transformer;
        buffer = Bytes.alloc(chunkSize);
        transformedBuffer = new Deque();
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
        if (isEOF) {
            throw new EndOfFileException();
        } else if (!transformedBuffer.isEmpty()) {
            return unshiftTransformed(bytes, position, length);
        }

        var transformedBytes = readAndTransform(length);

        if (transformedBytes.length <= length) {
            bytes.blit(position, transformedBytes, 0, transformedBytes.length);
            return transformedBytes.length;
        }

        bytes.blit(position, transformedBytes, 0, length);

        for (index in length...transformedBytes.length) {
            transformedBuffer.push(transformedBytes.get(index));
        }

        return length;
    }

    function unshiftTransformed(bytes:Bytes, position:Int, length:Int):Int {
        var count = 0;

        for (index in 0...length) {
            switch (transformedBuffer.shift()) {
                case Some(byte):
                    bytes.set(position + index, byte);
                    count += 1;
                case None:
                    break;
            }
        }

        return count;
    }

    function readAndTransform(length:Int):Bytes {
        length = Std.int(Math.min(length, buffer.length));
        var sourceBytesRead;

        try {
            sourceBytesRead = source.readInto(buffer, 0, length);
        } catch (exception:EndOfFileException) {
            isEOF = true;
            return transformer.flush();
        }

        return transformer.transform(buffer.sub(0, sourceBytesRead));
    }

    public function readReady():Task<Source> {
        return source.readReady().continueWith(function (task) {
            task.getResult();
            return TaskTools.fromResult((this:Source));
        });
    }
}
