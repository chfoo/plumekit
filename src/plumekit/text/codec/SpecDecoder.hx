package plumekit.text.codec;

import plumekit.text.CodePointTools.INT_NULL;


class SpecDecoder extends SpecUTF8Decoder {
    var bomSeen = false;
    var fallbackEncoding:String;

    public function new(fallbackEncoding:String) {
        super();
        this.fallbackEncoding = fallbackEncoding;
    }

    override function checkBOM() {
        read3Bytes();

        var encoding;
        var byte1:Int = buffer.length >= 1 ? buffer.get(0) : INT_NULL;
        var byte2:Int = buffer.length >= 2 ? buffer.get(1) : INT_NULL;
        var byte3:Int = buffer.length >= 3 ? buffer.get(2) : INT_NULL;

        if (byte1 == 0xEF && byte2 == 0xBB && byte3 == 0xBF) {
            encoding = "UTF-8";
            bomSeen = true;
        } else if (byte1 == 0xFE && byte2 == 0xFF) {
            encoding = "UTF-16BE";
            bomSeen = true;
        } else if (byte1 == 0xFF && byte2 == 0xFE) {
            encoding = "UTF-16LE";
            bomSeen = true;
        } else {
            encoding = fallbackEncoding;
        }

        if (!bomSeen) {
            prependBufferToStream();
        } else if (bomSeen && encoding != "UTF-8" && buffer.length == 3) {
            stream.unshift(buffer.last());
        }

        decoderRunner = new DecoderRunner(Registry.getDecoderHandler(encoding));
    }
}
