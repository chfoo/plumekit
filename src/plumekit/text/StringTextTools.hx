package plumekit.text;

using unifill.Unifill;


class StringTextTools {
    public static function splitLines(text:String):Array<String> {
        var pattern = new EReg("\r\n|\r|\n", "g");
        return pattern.split(text);
    }

    public static function toTitleCase(text:String):String {
        var titleCasePattern = new EReg("([^a-z]|^)([a-z])([a-z]*)", "ig");
        return titleCasePattern.map(text, titleCaseCallback);
    }

    static function titleCaseCallback(pattern:EReg):String {
        var nonLetter = pattern.matched(1);
        var firstLetter = pattern.matched(2).toUpperCase();
        var remainingLetters = pattern.matched(3).toLowerCase();
        return '$nonLetter$firstLetter$remainingLetters';
    }

    public static function containsPredicate(text:String, predicate:Int->Bool):Bool {
        for (char in text.uIterator()) {
            if (predicate(char)) {
                return true;
            }
        }

        return false;
    }

    public static function trimPredicate(text:String,
            predicate:Int->Bool):String {
        var index = 0;
        var firstNonMatch = 0;
        var lastNonMatch = 0;

        for (char in text.uIterator()) {
            if (!predicate(char)) {
                if (firstNonMatch == 0) {
                    firstNonMatch = index;
                }

                lastNonMatch = index;
            }

            index += 1;
        }

        return text.uSubstring(firstNonMatch, lastNonMatch + 1);
    }

    public static function replacePredicate(text:String,
            searchPredicate:Int->Bool, replacement:String):String {
        var buffer = new StringBuf();

        for (char in text.uIterator()) {
            if (searchPredicate(char)) {
                buffer.add(replacement);
            } else {
                buffer.uAddChar(char);
            }
        }

        return buffer.toString();
    }
}
