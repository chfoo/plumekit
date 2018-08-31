package plumekit.text.unicode;

@:enum
abstract GeneralCategory(String) to String {
    var UppercaseLetter = "Lu";
    var LowercaseLetter = "Ll";
    var TitlecaseLetter = "Lt";
    var CasedLetter = "LC";
    var ModifierLetter = "Lm";
    var OtherLetter = "Lo";
    var Letter = "L";
    var NonspacingMark = "Mn";
    var SpacingMark = "Mc";
    var EnclosingMark = "Me";
    var Mark = "M";
    var DecimalNumber = "Nd";
    var LetterNumber = "Nl";
    var OtherNumber = "No";
    var Number = "N";
    var ConnectorPunctuation = "Pc";
    var DashPunctuation = "Pd";
    var OpenPunctuation = "Ps";
    var ClosePunctuation = "Pe";
    var InitialPunctuation = "Pi";
    var FinalPunctuation = "Pf";
    var OtherPunctuation = "Po";
    var Punctuation = "P";
    var MathSymbol = "Sm";
    var CurrencySymbol = "Sc";
    var ModifierSymbol = "Sk";
    var OtherSymbol = "So";
    var Symbol = "S";
    var SpaceSeparator = "Zs";
    var LineSeparator = "Zl";
    var ParagraphSeparator = "Zp";
    var Separator = "Z";
    var Control = "Cc";
    var Format = "Cf";
    var Surrogate = "Cs";
    var PrivateUse = "Co";
    var Unassigned = "Cn";
    var Other = "C";
}


@:enum
abstract BidiClass(String) to String {
    var LeftToRight = "L";
    var RightToLeft = "R";
    var ArabicLetter = "AL";
    var EuropeanNumber = "EN";
    var EuropeanSeparator = "ES";
    var EuropeanTerminator = "ET";
    var ArabicNumber = "AN";
    var CommonSeparator = "CS";
    var NonspacingMark = "NSM";
    var BoundaryNeutral = "BN";
    var ParagraphSeparator = "B";
    var SegmentSeparator = "S";
    var WhiteSpace = "WS";
    var OtherNeutral = "ON";
    var LeftToRightEmbedding = "LRE";
    var LeftToRightOverride = "LRO";
    var RightToLeftEmbedding = "RLE";
    var RightToLeftOverride = "RLO";
    var PopDirectionalFormat = "PDF";
    var LeftToRightIsolate = "LRI";
    var RightToLeftIsolate = "RLI";
    var FirstStrongIsolate = "FSI";
    var PopDirectionalIsolate = "PDI";
}


@:enum
abstract CanonicalCombiningClass(Int) to Int {
    var NotReordered = 0;
    var Overlay = 1;
    var Nukta = 7;
    var KanaVoicing = 8;
    var Virama = 9;
    var Ccc10 = 10;
    var Attached_Below_Left = 200;
    var Attached_Below = 202;
    var Attached_Above = 214;
    var Attached_Above_Right = 216;
    var BelowLeft = 218;
    var Below = 220;
    var BelowRight = 222;
    var Left = 224;
    var Right = 226;
    var AboveLeft = 228;
    var Above = 230;
    var AboveRight = 232;
    var DoubleBelow = 233;
    var DoubleAbove = 234;
    var IotaSubscript = 240;
}
