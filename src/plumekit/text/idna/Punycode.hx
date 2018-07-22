package plumekit.text.idna;

import unifill.Unicode;
import unifill.InternalEncoding;
import commonbox.ds.Deque;
import commonbox.ds.ArrayList;

using unifill.Unifill;
using plumekit.text.CodePointTools;


// RFC 3492 Implementation

class Punycode {
    public static function decode(text:String):String {
        var decoder = new PunycodeDecoder(text);
        return decoder.decode();
    }

    public static function encode(text:String):String {
        var encoder = new PunycodeEncoder(text);
        return encoder.encode();
    }
}


private class PunycodeParameters {
    public var base = 36;
    public var tmin = 1;
    public var tmax = 26;
    public var skew = 38;
    public var damp = 700;
    public var initialBias = 72;
    public var initialN = 128;
    public var deliminator = "-".code;

    public function new() {
    }
}


private class BasePunycodeCoder {
    var params:PunycodeParameters;

    public function new() {
        params = new PunycodeParameters();
    }

    function adapt(delta:Int, numPoints:Int, firstTime:Bool):Int {
        if (firstTime) {
            delta = Std.int(delta / params.damp);
        } else {
            delta = Std.int(delta / 2);
        }

        delta += Std.int(delta / numPoints);

        var k = 0;
        while (delta > Std.int((params.base - params.tmin) * params.tmax / 2)) {
            delta = Std.int(delta / (params.base - params.tmin));
            k += params.base;
        }

        return k + Std.int(
            (params.base - params.tmin + 1) * delta
            / (delta + params.skew));
    }

    function textToCodePointDeque(text:String):Deque<Int> {
        var codePoints = new Deque<Int>();

        for (codePoint in text.uIterator()) {
            codePoints.push(codePoint);
        }

        return codePoints;
    }

    function decodeDigit(codePoint:Int) {
        if (codePoint - 48 < 10) {
            return codePoint - 22;
        } else if (codePoint - 65 < 26) {
            return codePoint - 65;
        } else if (codePoint - 97 < 26) {
            return codePoint - 97;
        } else {
            return params.base;
        }
    }

    function encodeDigit(digit:Int):Int {
        if (digit < 26) {
            return digit + 22 + 75;
        } else {
            return digit + 22;
        }
    }
}


private class PunycodeDecoder extends BasePunycodeCoder {
    var output:ArrayList<Int>;
    var input:Deque<Int>;

    public function new(text:String) {
        super();
        output = new ArrayList<Int>();
        input = textToCodePointDeque(text);
    }

    public function decode():String {
        var n = params.initialN;
        var i = 0;
        var bias = params.initialBias;

        segregateBasicCodePoint();

        while (!input.isEmpty()) {
            var oldi = i;
            var w = 1;
            var k = params.base;

            while (true) {
                var codePoint;

                switch input.shift() {
                    case Some(codePoint_):
                        codePoint = codePoint_;
                    case None:
                        throw new Exception.ValueException();
                }

                var digit = decodeDigit(codePoint);
                i = i + digit * w; // TODO: fail on overflow
                var t;

                if (k <= bias) {
                    t = params.tmin;
                } else if (k >= bias + params.tmax) {
                    t = params.tmax;
                } else {
                    t = k - bias;
                }

                if (digit < t) {
                    break;
                }
                w = w * (params.base - t); // TODO: fail on overflow

                k += params.base;
            }

            bias = adapt(i - oldi, output.length + 1, oldi == 0);
            n = n + Std.int(i / (output.length + 1)); //  TODO: fail on overflow
            i = i % (output.length + 1);
            output.insert(i, n);
            i += 1;
        }

        return InternalEncoding.fromCodePoints(output);
    }

    function segregateBasicCodePoint() {
        var lastDeliminatorIndex;

        switch input.lastIndexOf(params.deliminator) {
            case Some(index):
                lastDeliminatorIndex = index;
            case None:
                return;
        }

        if (lastDeliminatorIndex == 0) {
            return;
        }

        for (index in 0...input.length) {
            switch input.shift() {
                case Some(codePoint):
                    if (index == lastDeliminatorIndex) {
                        break;
                    }

                    output.push(codePoint);

                    if (!codePoint.isASCII()) {
                        throw new Exception.ValueException();
                    }
                case None:
                    break;
            }
        }
    }
}


private class PunycodeEncoder extends BasePunycodeCoder {
    var input:Deque<Int>;
    var output:ArrayList<Int>;

    public function new(text:String) {
        super();
        output = new ArrayList<Int>();
        input = textToCodePointDeque(text);
    }

    public function encode():String {
        var n = params.initialN;
        var delta = 0;
        var bias = params.initialBias;
        var h = numberOfBasicCodePoints();
        var b = h;

        copyBasicCodePoints();

        if (b > 0) {
            output.push(params.deliminator);
        }

        while (h < input.length) {
            var m = minimumCodePointN(n);
            delta = delta + (m - n) * (h + 1); // TODO: fail on overflow
            n = m;

            for (codePoint in input) {
                if (codePoint < n) {
                    delta += 1;
                    // TODO: fail on overflow
                } else if (codePoint == n) {
                    var q = delta;
                    var k = params.base;

                    while (true) {
                        var t;

                        if (k <= bias) {
                            t = params.tmin;
                        } else if (k >= bias + params.tmax) {
                            t = params.tmax;
                        } else {
                            t = k - bias;
                        }

                        if (q < t) {
                            break;
                        }

                        output.push(encodeDigit(t + ((q - t) % (params.base - t))));
                        q = Std.int((q - t) / (params.base - t));

                        k += params.base;
                    }

                    output.push(encodeDigit(q));

                    bias = adapt(delta, h + 1, h == b);
                    delta = 0;
                    h += 1;
                }
            }

            delta += 1;
            n += 1;
        }

        return InternalEncoding.fromCodePoints(output);
    }

    function numberOfBasicCodePoints():Int {
        var count = 0;

        for (codePoint in input) {
            if (codePoint.isASCII()) {
                count += 1;
            }
        }

        return count;
    }

    function copyBasicCodePoints() {
        for (codePoint in input) {
            if (codePoint.isASCII()) {
                output.push(codePoint);
            } else {
                break;
            }
        }
    }

    function minimumCodePointN(n:Int):Int {
        var min = Unicode.maxCodePoint;

        for (codePoint in input) {
            if (codePoint >= n && codePoint < min) {
                min = codePoint;
            }
        }

        return min;
    }
}
