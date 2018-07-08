package plumekit.stream;

import commonbox.ds.Deque;
import haxe.ds.Option;

using unifill.Unifill;


class TextScanner {
    static inline var CR = "\r".code;
    static inline var LF = "\n".code;

    public var bufferLength(get, never):Int;

    var buffer:Deque<Int>; // in code points
    var isEOF = false;

    public function new(maxBufferSize:Int = 16384) {
        buffer = new Deque(maxBufferSize);
    }

    function get_bufferLength():Int {
        return buffer.length;
    }

    public function isEmpty():Bool {
        return buffer.isEmpty();
    }

    public function setEOF() {
        isEOF = true;
    }

    public function shiftString(?amount:Int):String {
        amount = amount != null ? amount : buffer.length;
        var textBuffer = new StringBuf();

        while (textBuffer.length < amount) {
            switch (buffer.shift()) {
                case Some(codePoint):
                    textBuffer.uAddChar(codePoint);
                case None:
                    break;
            }
        }

        return textBuffer.toString();
    }

    public function pushString(text:String) {
        for (codePoint in text.uIterator()) {
            buffer.push(codePoint);
        }
    }

    public function scanLine(keepEnd:Bool = false):Option<String> {
        var deliminatorIndex = -1;
        var deliminatorLength = 0;
        var deliminatorCodePoint = -1;
        var previousCodePoint = -1;
        var index = 0;

        for (codePoint in buffer) {
            if (deliminatorIndex < 0 && (codePoint == CR || codePoint == LF)) {
                deliminatorCodePoint = codePoint;
                deliminatorIndex = index;
                deliminatorLength = 1;
            } else if (codePoint == LF && previousCodePoint == CR) {
                deliminatorLength += 1;
                break;
            } else if (deliminatorIndex >= 0) {
                break;
            }

            previousCodePoint = codePoint;
            index += 1;
        }

        var ambiguous = deliminatorCodePoint == CR
            && deliminatorIndex == buffer.length - 1;

        if (deliminatorIndex < 0 || ambiguous && !isEOF) {
            return None;
        }

        var amount = deliminatorIndex;

        if (keepEnd) {
            amount += deliminatorLength;
        }

        var text = shiftString(amount);

        if (!keepEnd) {
            discardBuffer(deliminatorLength);
        }

        return Some(text);
    }

    function discardBuffer(amount:Int) {
        for (count in 0...amount) {
            buffer.shift();
        }
    }
}
