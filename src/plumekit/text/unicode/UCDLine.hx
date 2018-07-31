package plumekit.text.unicode;

import haxe.ds.Option;


class UCDLine {
    public var codePoint:Int = -1;
    public var endCodePoint:Option<Int> = None;
    public var fields:Array<String>;

    public function new() {
        fields = [];
    }
}
