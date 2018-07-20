package plumekit.text;

import unifill.CodePoint;
import commonbox.ds.Deque;

using unifill.Unifill;


class CodePointBuffer extends Deque<CodePoint> {
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
        return this.uToString();
    }
}
