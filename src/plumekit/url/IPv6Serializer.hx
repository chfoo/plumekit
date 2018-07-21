package plumekit.url;

import haxe.ds.Option;
import haxe.io.UInt16Array;

using StringTools;


class IPv6Serializer {
    public static function serialize(address:UInt16Array) {
        var output = new StringBuf();
        var compress = findLongestZeros(address);
        var ignore0 = false;

        for (pieceIndex in 0...8) {
            var piece = address.get(pieceIndex);

            if (ignore0 && piece == 0) {
                continue;
            } else if (ignore0) {
                ignore0 = false;
            }

            switch compress {
                case Some(compress):
                    if (compress == pieceIndex) {
                        var separator = pieceIndex == 0 ? "::" : ":";
                        output.add(separator);
                        ignore0 = true;
                        continue;
                    }
                case None:
                    // pass
            }

            output.add(piece.hex().toLowerCase());

            if (pieceIndex != 7) {
                output.add(":");
            }
        }

        return output.toString();
    }

    static function findLongestZeros(address:UInt16Array):Option<Int> {
        var longestZeroIndex = -1;
        var longestZeroCount = 0;
        var zeroCount = 0;

        for (index in 0...address.length) {
            var reverseIndex = address.length - index;
            var piece = address.get(reverseIndex);

            if (piece == 0) {
                zeroCount += 1;
            } else {
                zeroCount = 0;
            }

            if (zeroCount >= longestZeroCount) {
                longestZeroCount = zeroCount;
                longestZeroIndex = reverseIndex;
            }
        }

        if (longestZeroCount > 1) {
            return Some(longestZeroIndex);
        } else {
            return None;
        }
    }
}
