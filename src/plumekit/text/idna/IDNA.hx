package plumekit.text.idna;

import plumekit.Exception.ValueException;
import plumekit.text.idna.Processor;

using plumekit.text.StringTextTools;


@:structInit
class IDNAToAsciiFlags extends ProcessorFlags {
    public var verifyDnsLength:Bool = false;

    public function new() {
        super();
    }
}


typedef IDNAToUnicodeFlags = ProcessorFlags;


class IDNA {
    public static function toASCII(domainName:String, flags:IDNAToAsciiFlags):String {
        var processor = new Processor(domainName, flags);
        var labels = processor.process().split(".");
        var hasError = processor.hasError;

        for (index in 0...labels.length) {
            if (!labels[index].isASCII()) {
                labels[index] = Processor.ACE_PRFIX + Punycode.encode(labels[index]);
            }
        }

        if (flags.verifyDnsLength) {
            // TODO:
        }

        if (hasError) {
            throw new ValueException("Validation failed.");
        }

        return labels.join(".");
    }

    public static function toUnicode(domainName:String, flags:IDNAToUnicodeFlags):String {
        var processor = new Processor(domainName, flags);
        return processor.process();
    }
}
