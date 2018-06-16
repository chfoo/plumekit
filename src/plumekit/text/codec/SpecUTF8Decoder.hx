package plumekit.text.codec;

import haxe.io.Bytes;


class SpecUTF8Decoder implements Decoder {
    var buffer:Stream;
    var stream:Stream;
    var passThrough = false;
    var decoderRunner:DecoderRunner;

    public function new() {
        buffer = new Stream();
        stream = new Stream();
    }

    public function decode(data:Bytes, incremental:Bool = false):String {
        if (passThrough) {
            return decoderRunner.decode(data, incremental);
        }

        for (index in 0...data.length) {
            stream.push(data.get(index));
        }

        if (stream.length >= 3 || !incremental) {
            checkBOM();
            passThrough = incremental;
            var result = decoderRunner.decode(streamToBytes(), incremental);

            buffer.clear();
            stream.clear();

            return result;

        } else {
            return "";
        }
    }

    public function flush():String {
        if (passThrough) {
            return decoderRunner.flush();
        } else {
            checkBOM();
            var result = decoderRunner.decode(streamToBytes());

            buffer.clear();
            stream.clear();

            return result;
        }
    }

    function checkBOM() {
        read3Bytes();

        var byte1 = buffer.length >= 1 ? buffer.get(0) : CodecTools.INT_NULL;
        var byte2 = buffer.length >= 2 ? buffer.get(1) : CodecTools.INT_NULL;
        var byte3 = buffer.length >= 3 ? buffer.get(2) : CodecTools.INT_NULL;

        if (!(byte1 == 0xEF && byte2 == 0xBB && byte3 == 0xBF)) {
            prependBufferToStream();
        }

        decoderRunner = new DecoderRunner(Registry.getDecoderHandler("UTF-8"));
    }

    function read3Bytes() {
        for (count in 0...3) {
            switch (stream.shift()) {
                case Some(byte):
                    buffer.push(byte);
                case None:
                    break;
            }
        }
    }

    function prependBufferToStream() {
        while (true) {
            switch (buffer.pop()) {
                case Some(byte):
                    stream.unshift(byte);
                case None:
                    break;
            }
        }
    }

    function streamToBytes():Bytes {
        var bytes = Bytes.alloc(stream.length);

        var index = 0;
        for (item in stream) {
            bytes.set(index, item);
            index += 1;
        }

        return bytes;
    }
}
