package plumekit.url;

import haxe.io.UInt16Array;
import plumekit.text.IntParser;
import plumekit.text.CodePointTools.INT_NULL;

using StringTools;
using plumekit.text.CodePointTools;


class IPv6Parser {
    // TODO: break up this function into smaller pieces
    public static function parse(input:String, ?validationError:ValidationError):ParserResult<UInt16Array> {
        if (validationError == null) {
            validationError = new ValidationError();
        }

        var address = new UInt16Array(8);
        var pieceIndex = 0;
        var compress = INT_NULL;
        var pointer = new StringPointer(input);

        if (pointer.c == ":".code) {
            if (!pointer.remaining.startsWith(":")) {
                validationError.set();
                return Failure;
            }

            pointer.increment(2);
            pieceIndex += 1;
            compress = pieceIndex;
        }

        while (!pointer.isEOF()) {
            if (pieceIndex == 8) {
                validationError.set();
                return Failure;

            } else if (pointer.c == ":".code) {
                if (compress != INT_NULL) {
                    validationError.set();
                    return Failure;
                }

                pointer.increment(1);
                pieceIndex += 1;
                compress = pieceIndex;
                continue;
            }

            var value = 0;
            var length = 0;

            while (length < 4 && pointer.c.isASCIIHexDigit()) {
                value = value * 0x10 + IntParser.charCodeToInt(pointer.c);
                pointer.increment(1);
                length += 1;
            }

            if (pointer.c == ".".code) {
                if (length == 0) {
                    validationError.set();
                    return Failure;
                }

                pointer.increment(-1);

                if (pieceIndex > 6) {
                    validationError.set();
                    return Failure;
                }

                var numbersSeen = 0;

                while (!pointer.isEOF()) {
                    var ipv4Piece = INT_NULL;

                    if (numbersSeen > 0) {
                        if (pointer.c == ".".code && numbersSeen < 4) {
                            pointer.increment(1);
                        } else {
                            validationError.set();
                            return Failure;
                        }
                    }

                    if (!pointer.c.isASCIIDigit()) {
                        validationError.set();
                        return Failure;
                    }

                    while (pointer.c.isASCIIDigit()) {
                        var number = IntParser.charCodeToInt(pointer.c);

                        if (ipv4Piece == INT_NULL) {
                            ipv4Piece = number;
                        } else if (ipv4Piece == 0) {
                            validationError.set();
                            return Failure;
                        } else {
                            ipv4Piece = ipv4Piece * 10 + number;
                        }

                        if (ipv4Piece > 255) {
                            validationError.set();
                            return Failure;
                        }

                        pointer.increment(1);
                    }

                    address[pieceIndex] = address[pieceIndex] * 0x100 + ipv4Piece;
                    numbersSeen += 1;

                    if (numbersSeen == 2 || numbersSeen == 4) {
                        pieceIndex += 1;
                    }
                }

                if (numbersSeen != 4) {
                    // validation error
                    return Failure;
                }

                break;
            } else if (pointer.c == ":".code) {
                pointer.increment(1);

                if (pointer.c == INT_NULL) {
                    validationError.set();
                    return Failure;
                }
            } else if (pointer.c != INT_NULL) {
                validationError.set();
                return Failure;
            }

            address[pieceIndex] = value;
            pieceIndex += 1;
        }

        if (compress != INT_NULL) {
            var swaps = pieceIndex - compress;
            pieceIndex = 7;

            while (pieceIndex != 0 && swaps > 0) {
                var tmpAddress = address[pieceIndex];
                address[pieceIndex] = address[compress + swaps - 1];
                address[compress + swaps - 1] = tmpAddress;

                pieceIndex -= 1;
                swaps -= 1;
            }
        } else if (compress == INT_NULL && pieceIndex != 8) {
            validationError.set();
            return Failure;
        }

        return Result(address);
    }
}
