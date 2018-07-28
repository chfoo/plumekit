package plumekit.url;


class IDNAHook {
    public static function domainToASCII(domain:String,
            validationError:ValidationError, beStrict:Bool = false):ParserResult<String> {
        // throw "not implemented";
        trace("not implemented");
        return Result(domain);
    }

    public static function domainToUnicode(domain:String,
            validationError:ValidationError):ParserResult<String> {
        // throw "not implemented";
        trace("not implemented");
        return Result(domain);
    }
}
