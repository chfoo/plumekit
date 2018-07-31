package plumekit.text.idna;

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

            validateLabel(label);
        }
    }

    function validateLabel(label:String) {
        // TODO: Unicode Normalization Form NFC
        // TODO: begin with a combining mark

        var invalid =
            (flags.checkHyphens && (label.uIndexOf("-") == 2 || label.uIndexOf("-", 3) == 3))
            || label.indexOf(".") >= 0;

        if (invalid) {
            hasError = true;
            return;
        }

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

        if (flags.checkJoiners) {
            // TODO:
        }

        if (flags.checkBidi) {
            // TODO:
        }
    }
}
