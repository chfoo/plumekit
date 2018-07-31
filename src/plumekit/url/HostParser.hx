package plumekit.url;

import plumekit.text.codec.SpecHook;
import plumekit.url.Host;
import plumekit.url.IPv4Parser;
import plumekit.url.ParserResult;

using plumekit.text.StringTextTools;
using StringTools;


class HostParser {
    public static function parse(input:String, validationError:ValidationError,
            isNotSpecial:Bool = false):ParserResult<Host> {
        if (input.startsWith("[")) {
            if (!input.endsWith("]")) {
                validationError.set();
                return Failure;
            }

            var bracketStripped = input.substring(1, input.length -1);

            switch IPv6Parser.parse(bracketStripped, validationError) {
                case Result(pieces):
                    return Result(IPv6Address(pieces));
                case Failure:
                    return Failure;
            }
        } else if (isNotSpecial) {
            switch OpaqueHostParser.parse(input, validationError) {
                case Result(host):
                    return Result(OpaqueHost(host));
                case Failure:
                    return Failure;
            }
        }

        var domain = SpecHook.utf8WithoutBOMDecode(PercentEncoder.stringPercentDecode(input));
        var asciiDomainResult = IDNAHook.domainToASCII(domain, validationError);
        var asciiDomain;

        switch (asciiDomainResult) {
            case Failure:
                validationError.set();
                return Failure;
            case Result(asciiDomain_):
                asciiDomain = asciiDomain_;
        }

        if (asciiDomain.containsPredicate(isForbiddenHostCodePoint)) {
            validationError.set();
            return Failure;
        }

        var ipv4Host = IPv4Parser.parse(asciiDomain, validationError);

        switch (ipv4Host) {
            case IPv4ParserResult.IPv4(ipv4):
                return Result(IPv4Address(ipv4));
            case IPv4ParserResult.Failure:
                return Failure;
            default:
                return Result(Domain(asciiDomain));
        }
    }

    public static function isForbiddenHostCodePoint(codePoint:Int):Bool {
        return codePoint == 0
            || codePoint == "\t".code
            || codePoint == "\r".code
            || codePoint == "\n".code
            || codePoint == " ".code
            || codePoint == "#".code
            || codePoint == "%".code
            || codePoint == "/".code
            || codePoint == ":".code
            || codePoint == "?".code
            || codePoint == "@".code
            || codePoint == "[".code
            || codePoint == "\\".code
            || codePoint == "]".code;
    }
}
