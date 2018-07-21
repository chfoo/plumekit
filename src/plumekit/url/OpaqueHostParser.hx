package plumekit.url;

using plumekit.text.StringTextTools;
using unifill.Unifill;


class OpaqueHostParser {
    public static function parse(input:String, validationError:ValidationError):ParserResult<String> {
        if (input.containsPredicate(isForbiddenHostCodePointExcludingPercent)) {
            validationError.set();
            return Failure;
        }

        var outputBuf = new StringBuf();

        for (codePoint in input.uIterator()) {
            var result = PercentEncoder.utf8PercentEncode(
                codePoint, PercentEncodeSet.c0Control);
            outputBuf.add(result);
        }

        return Result(outputBuf.toString());
    }

    public static function isForbiddenHostCodePointExcludingPercent(codePoint:Int):Bool {
        return codePoint != "%".code && HostParser.isForbiddenHostCodePoint(codePoint);
    }
}
