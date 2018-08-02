package plumekit.text.idna;

import plumekit.text.unicode.UnicodeDB;
import plumekit.text.unicode.PropertyValues;
import plumekit.Exception.ValueException;

using unifill.Unifill;
using StringTools;


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
            // TODO:
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
