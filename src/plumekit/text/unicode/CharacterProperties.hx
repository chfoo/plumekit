package plumekit.text.unicode;


class CharacterProperties {
    public var codePoint:Int;
    public var name:String = "";  // 1
    public var generalCategory:String = "";  // 2
    public var canonicalCombiningClass:Int = 0;  // 3
    public var bidiClass:String = "";  // 4
    public var decompositionType:String = "";  // <5>
    public var decompositionMapping:String = ""; // 5
    public var numericType:String = ""; // 6 = Decimal, 7 = Digit, 8 = Numeric
    public var numericValue:String = "";
    public var bidiMirrored:Bool = false; // 9
    public var simpleUppercaseMapping:String = ""; // 12
    public var simpleLowercaseMapping:String = ""; // 13
    public var simpleTitlecaseMapping:String = ""; // 14

    public function new(codePoint:Int) {
        this.codePoint = codePoint;
    }
}
