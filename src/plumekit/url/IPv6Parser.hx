package plumekit.url;

import plumekit.text.IntParser;

using plumekit.url.ParserTools;
using StringTools;


enum IPv6ParserResult {
    Failure;
    Address(piece:Array<Int>);
}


class IPv6Parser {
    // TODO: break up this function into smaller pieces
    // TODO: set validation error
    public static function parse(input:String, ?validationError:ValidationError) {
        if (validationError == null) {
            validationError = new ValidationError();
        }

        var address = [for (i in 0...8) 0];
        var pieceIndex = 0;
        var compress = ParserTools.INT_NULL;
        var pointer = new StringPointer(input);

        if (pointer.c == ":".code) {
            if (!pointer.remaining.startsWith(":")) {
                // validation error
                return Failure;
            }

            pointer.increment(2);
            pieceIndex += 1;
            compress = pieceIndex;
        }

        while (pointer.c != ParserTools.INT_NULL) {
            if (pieceIndex == 8) {
                // validation error
                return Failure;

            } else if (pointer.c == ":".code) {
                if (compress != ParserTools.INT_NULL) {
                    // validation error
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
            }

            if (pointer.c == ".".code) {
                if (length == 0) {
                    // validation error
                    return Failure;
                }

                pointer.increment(-1);

                if (pieceIndex > 6) {
                    // validation error
                    return Failure;
                }

                var numbersSeen = 0;

                while (pointer.c != ParserTools.INT_NULL) {
                    var ipv4Piece = ParserTools.INT_NULL;

                    if (numbersSeen > 0) {
                        if (pointer.c == ".".code && numbersSeen < 4) {
                            pointer.increment(1);
                        } else {
                            // validation error
                            return Failure;
                        }
                    }

                    if (!pointer.c.isASCIIDigit()) {
                        // validation error
                        return Failure;
                    }

                    while (pointer.c.isASCIIDigit()) {
                        var number = IntParser.charCodeToInt(pointer.c);

                        if (ipv4Piece == ParserTools.INT_NULL) {
                            ipv4Piece = number;
                        } else if (ipv4Piece == 0) {
                            // validation error
                            return Failure;
                        } else {
                            ipv4Piece = ipv4Piece * 10 + number;
                        }

                        if (ipv4Piece > 255) {
                            // validation error
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

                if (pointer.c == ParserTools.INT_NULL) {
                    // validation error
                    return Failure;
                }
            } else if (pointer.c != ParserTools.INT_NULL) {
                // validation error
                return Failure;
            }

            address[pieceIndex] = value;
            pieceIndex += 1;
        }

        if (compress != ParserTools.INT_NULL) {
            var swaps = pieceIndex - compress;
            pieceIndex = 7;

            while (pieceIndex != 0 && swaps > 0) {
                var tmpAddress = address[pieceIndex];
                address[pieceIndex] = address[compress + swaps - 1];
                address[compress + swaps - 1] = tmpAddress;

                pieceIndex += 1;
                swaps += 1;
            }
        } else if (compress == ParserTools.INT_NULL && pieceIndex != 8) {
            // validation error
            return Failure;
        }

        return Address(address);
    }
}
