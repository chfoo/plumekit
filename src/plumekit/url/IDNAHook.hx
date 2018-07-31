package plumekit.url;

import plumekit.Exception.ValueException;
import plumekit.text.idna.IDNA;


class IDNAHook {
    public static function domainToASCII(domain:String,
            validationError:ValidationError, beStrict:Bool = false)
            :ParserResult<String> {

        var flags = new IDNAToAsciiFlags();
        flags.useSTD3ASCIIRules = beStrict;
        flags.checkHyphens = false;
        flags.checkBidi = true;
        flags.checkJoiners = true;
        flags.transitionalProcessing = false;
        flags.verifyDnsLength = beStrict;

        try {
            return Result(IDNA.toASCII(domain, flags));
        } catch (exception:ValueException) {
            return Failure;
        }
    }

    public static function domainToUnicode(domain:String,
            validationError:ValidationError):ParserResult<String> {
        var flags = new IDNAToUnicodeFlags();
        flags.checkHyphens = false;
        flags.checkBidi = true;
        flags.checkJoiners = true;
        flags.useSTD3ASCIIRules = false;
        flags.transitionalProcessing = false;

        return Result(domain);
    }
}
