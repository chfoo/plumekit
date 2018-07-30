package plumekit.url;


enum IPv4ParserResult {
    Hostname(hostname:String);
    IPv4(ipv4:UInt);
    Failure;
}


class IPv4Parser {
    // TODO: break up this function into smaller pieces
    public static function parse(input:String, ?validationError:ValidationError):IPv4ParserResult {
        if (validationError == null) {
            validationError = new ValidationError();
        }

        var validationErrorFlag = false;
        var parts = input.split(".");

        if (parts.length > 0 && parts[parts.length - 1] == "") {
            validationErrorFlag = true;

            if (parts.length > 0) {
                parts.pop();
            }
        }

        if (parts.length > 4) {
            return Hostname(input);
        }

        var numbers:Array<Float> = [];

        for (part in parts) {
            if (part == "") {
                return Hostname(input);
            }

            var validationErrorFlagWrapper = { value: validationErrorFlag };
            var n = IPv4NumberParser.parse(part, validationErrorFlagWrapper);
            validationErrorFlag = validationErrorFlagWrapper.value;

            switch (n) {
                case Failure:
                    return Hostname(input);
                case Result(value):
                    numbers.push(value);
                case Overflow:
                    numbers.push(Math.POSITIVE_INFINITY);
            }
        }

        if (validationErrorFlag) {
            validationError.set();
        }

        for (number in numbers) {
            if (number > 255) {
                validationError.set();
            }
        }

        for (number in numbers.slice(0, -1)) {
            if (number > 255) {
                return Failure;
            }
        }

        if (numbers[numbers.length - 1] >= Math.pow(256, 5 - numbers.length)) {
            validationError.set();
            return Failure;
        }

        var ipv4 = Std.int(numbers[numbers.length - 1]);
        numbers.pop();
        var counter = 0;

        for (n in numbers) {
            ipv4 += Std.int(n * Math.pow(256, 3 - counter));
            counter += 1;
        }

        return IPv4(ipv4);
    }
}
