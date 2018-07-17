package plumekit.text;

import commonbox.ds.Deque;

using unifill.Unifill;


class CodePointBuffer extends Deque<Int> {
    public function prependString(text:String) {
        var codePoints = [];

        for (codePoint in text.uIterator()) {
            codePoints.push(codePoint);
        }

        codePoints.reverse();

        for (codePoint in codePoints) {
            unshift(codePoint);
        }
    }

    override public function toString():String {
        var buf = new StringBuf();

        for (codePoint in this) {
            buf.uAddChar(codePoint);
        }

        return buf.toString();
    }
}
