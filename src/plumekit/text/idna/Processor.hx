package plumekit.text.idna;

import plumekit.text.unicode.UnicodeDB;
import plumekit.text.unicode.PropertyValues;
import plumekit.Exception.ValueException;

using unifill.Unifill;
using StringTools;
using plumekit.text.CodePointTools;


@:structInit
class ProcessorFlags {
    public var useSTD3ASCIIRules:Bool = false;
    public var checkHyphens:Bool = false;
    public var checkBidi:Bool = false;
    public var checkJoiners:Bool = false;
    public var transitionalProcessing:Bool = false;

    public function new() {
    }
}

// UTS #48 Implementation

class Processor {
    public static inline var ACE_PRFIX = "xn--";

    public var hasError(default, null) = false;
    var domainName:String;
    var labels:Array<String>;
    var flags:ProcessorFlags;
    var mappingTable:MappingTable;
    var isBidiDomainName:Bool = false;

    public function new(domainName:String, flags:ProcessorFlags) {
        this.domainName = domainName;
        this.flags = flags;
        mappingTable = new MappingTable(flags.useSTD3ASCIIRules);
    }

    public function process():String {
        map();
        normalize();
        breakToLabels();
        convertOrValidate();

        return labels.join(".");
    }

    function map() {
        var buffer = new CodePointBuffer();

        for (codePoint in domainName.uIterator()) {
            switch mappingTable.get(codePoint) {
                case Disallowed:
                    hasError = true;
                    buffer.push(codePoint);
                case Ignored:
                    // pass
                case Mapped(mapping):
                    for (mappedCodePoint in mapping) {
                        buffer.push(mappedCodePoint);
                    }
                case Deviation(mapping):
                    if (flags.transitionalProcessing) {
                        for (mappedCodePoint in mapping) {
                            buffer.push(mappedCodePoint);
                        }
                    } else {
                        buffer.push(codePoint);
                    }
                case Valid:
                    buffer.push(codePoint);
            }
        }

        domainName = buffer.toString();
    }

    function normalize() {
        // TODO: Unicode Normalization Form C
    }

    function breakToLabels() {
        labels = domainName.split(".");
    }

    function convertOrValidate() {
        for (index in 0...labels.length) {
            var label = labels[index];

            if (label.startsWith(ACE_PRFIX)) {
                try {
                    labels[index] = Punycode.decode(label.substr(ACE_PRFIX.length));
                } catch (exception:ValueException) {
                    hasError = true;
                    continue;
                }
            }
        }

        checkIsBidiDomainName();

        for (label in labels) {
            validateLabel(label);

            if (hasError) {
                break;
            }
        }
    }

    function checkIsBidiDomainName() {
        for (label in labels) {
            for (codePoint in label.uIterator()) {
                var properties = UnicodeDB.getCharacterProperties(codePoint);
                var bidiClass = properties.bidiClass;

                if (bidiClass == BidiClass.RightToLeft
                        || bidiClass == BidiClass.ArabicLetter
                        || bidiClass == BidiClass.ArabicNumber) {
                    isBidiDomainName = true;
                    return;
                }
            }
        }
    }

    function validateLabel(label:String) {
        // TODO: Unicode Normalization Form NFC

        if (flags.checkHyphens) {
            validateCheckHyphens(label);
        }

        hasError = hasError || label.indexOf(".") >= 0;

        validateBeginCombiningMark(label);
        validateCodePointStatus(label);

        if (hasError) {
            return;
        }

        if (flags.checkJoiners) {
            validateJoiners(label);
        }

        if (flags.checkBidi && isBidiDomainName) {
            validateBidi(label);
        }
    }

    function validateCheckHyphens(label:String) {
        hasError = hasError || label.uIndexOf("-") == 2 || label.uIndexOf("-", 3) == 3;
    }

    function validateBeginCombiningMark(label:String) {
        if (label == "") {
            return;
        }
        var codePoint = label.uCharCodeAt(0);
        var properties = UnicodeDB.getCharacterProperties(codePoint);

        hasError = hasError
            || properties.generalCategory.startsWith(GeneralCategory.Mark);
    }

    function validateCodePointStatus(label:String) {
        for (codePoint in label.uIterator()) {
            if (flags.transitionalProcessing) {
                if (mappingTable.get(codePoint) != Valid) {
                    hasError = true;
                    return;
                }
            } else {
                switch mappingTable.get(codePoint) {
                    case Valid | Deviation(_): // pass
                    default:
                        hasError = true;
                        return;
                }
            }
        }
    }

    function validateJoiners(label:String) {
        var previousCodePoint = -1;
        var katakanaMiddleDotChecked = false;
        var hasArabicIndicDigits = false;
        var hasExtendedArabicIndicDigits = false;
        var index = 0;

        for (codePoint in (label + " ").uIterator()) {
            switch (codePoint:Int) {
                case 0x200c: // Zero width non joiner
                    if (getCombiningClass(previousCodePoint) == CanonicalCombiningClass.Virama) {
                        // ok
                    } else {
                        validateZeroWidthNonJoiner(index, label);
                    }
                case 0x200d: // Zero width joiner
                    if (getCombiningClass(previousCodePoint) != CanonicalCombiningClass.Virama) {
                        hasError = true;
                    }
                case 0x00b7: // Middle dot
                    if (previousCodePoint != 0x006c) {
                        hasError = true;
                    }
                case 0x05f3 | 0x05f4: // Hebrew punctuation geresh, gershayim
                    if (getScript(previousCodePoint) != "Hebrew") {
                        hasError = true;
                    }
                case 0x30fb: // Katakana middle dot
                    if (!katakanaMiddleDotChecked) {
                        validateKatakanaMiddleDot(label);
                        katakanaMiddleDotChecked = true;
                    }
            }

            switch previousCodePoint {
                case 0x00b7: // Middle dot
                    if (codePoint != 0x006c) {
                        hasError = true;
                    }
                case 0x0375: // Greek lower numerical sign (keraia)
                    if (getScript(codePoint) != "Greek") {
                        hasError = true;
                    }
            }

            if (codePoint.isInRange(0x0660, 0x0669)) {
                hasArabicIndicDigits = true;
            }

            if (codePoint.isInRange(0x6f0, 0x06f9)) {
                hasExtendedArabicIndicDigits = true;
            }

            if (hasArabicIndicDigits && hasExtendedArabicIndicDigits) {
                hasError = true;
            }

            if (hasError) {
                break;
            }

            index += 1;
        }
    }

    function getCombiningClass(codePoint:Int):Int {
        if (codePoint < 0) {
            return 0;
        }

        var properties = UnicodeDB.getCharacterProperties(codePoint);
        return properties.canonicalCombiningClass;
    }

    function getScript(codePoint:Int):String {
        // TODO:
        return "Unknown";
    }

    function getJoiningType(codePoint:Int):String {
        // TODO:
        return "";
    }

    function validateZeroWidthNonJoiner(index:Int, label:String) {
        var beforePattern = ~/.*[LD]T*$/;
        var afterPattern = ~/^T*[RD]/;

        var beforeMatched = beforePattern.match(label.uSubstr(0, index));
        var afterMatched = afterPattern.match(label.uSubstr(index + 1));

        if (!beforeMatched || !afterMatched) {
            hasError = true;
        }
    }

    function stringToJoiningTypeTokens(label:String):String {
        var buf = new StringBuf();

        for (codePoint in label.uIterator()) {
            if (codePoint == 0x200c) {
                buf.uAddChar(codePoint);
            } else {
                buf.add(getJoiningType(codePoint));
            }
        }

        return buf.toString();
    }

    function validateKatakanaMiddleDot(label:String) {
        for (codePoint in label.uIterator()) {
            var script = getScript(codePoint);

            switch script {
                case "Hiragana" | "Katakana" | "Han":
                    return;  // at least one
                default:
                    continue;
            }
        }

        hasError = true;
    }

    function validateBidi(label:String) {
        if (label == "") {
            return;
        }

        // RFC 5893 implementation
        var firstChar = label.uCharCodeAt(0);
        var firstCharProp = UnicodeDB.getCharacterProperties(firstChar);

        if (firstCharProp.bidiClass == BidiClass.LeftToRight) {
            validateBidiLTR(label);
        } else if (firstCharProp.bidiClass == BidiClass.RightToLeft
                || firstCharProp.bidiClass == BidiClass.ArabicLetter) {
            validateBidiRTL(label);
        } else {
            hasError = true;
        }
    }

    function validateBidiLTR(label:String) {
        var pattern = ~/(L,|EN,|ES,|CS,|ET,|ON,|BN,|NSM,)*(L,|EN,)(NSM,)*/;
        var tokens = stringToBidiTokens(label);

        if (!pattern.match(tokens)) {
            hasError = true;
        }
    }

    function validateBidiRTL(label:String) {
        var pattern = ~/(R,|AL,|AN,|EN,|ES,|CS,|ET,|ON,|BN,|NSM,)*(R,|AL,|EN,|AN,)(NSM,)*/;
        var tokens = stringToBidiTokens(label);

        if (!pattern.match(tokens)) {
            hasError = true;
            return;
        }

        var europeanNumberPresent = tokens.indexOf("EN,") >= 0;
        var arabicNumberPresent = tokens.indexOf("AN,") >= 0;

        if (europeanNumberPresent && arabicNumberPresent) {
            hasError = true;
        }
    }

    static function stringToBidiTokens(text:String):String {
        var classes = [];

        for (codePoint in text.uIterator()) {
            var properties = UnicodeDB.getCharacterProperties(codePoint);
            var bidiClass = properties.bidiClass;
            classes.push(bidiClass);
        }

        return classes.join(",") + ",";
    }
}
