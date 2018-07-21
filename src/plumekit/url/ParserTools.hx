package plumekit.url;

import haxe.io.Bytes;


class ParserTools {
    public static function splitOnByte(bytes:Bytes, byte:Int):Array<Bytes> {
        var output = [];

        var lowerIndex = 0;

        for (upperIndex in 0...bytes.length) {
            if (bytes.get(upperIndex) == byte) {
                output.push(bytes.sub(lowerIndex, upperIndex));
                lowerIndex = upperIndex;
            }
        }

        output.push(bytes.sub(lowerIndex, bytes.length));

        return output;
    }
}
