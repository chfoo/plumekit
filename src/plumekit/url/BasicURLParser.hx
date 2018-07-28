package plumekit.url;

import plumekit.text.IntParser;
import haxe.io.Bytes;
import haxe.ds.Option;
import haxe.io.BytesBuffer;
import plumekit.text.codec.Registry;
import plumekit.text.codec.SpecHook;
import plumekit.text.CodePointBuffer;
import plumekit.text.CodePointTools.INT_NULL;
import plumekit.url.ParserResult;

using commonbox.utils.OptionTools;
using plumekit.text.CodePointTools;
using plumekit.text.StringTextTools;
using plumekit.url.ParserTools;
using StringTools;
using unifill.Unifill;


enum BasicURLParserState {
    SchemeStartState;
    SchemeState;
    NoSchemeState;
    SpecialRelativeOrAuthorityState;
    PathOrAuthorityState;
    RelativeState;
    RelativeSlashState;
    SpecialAuthoritySlashesState;
    SpecialAuthorityIgnoreSlashesState;
    AuthorityState;
    HostState;
    HostnameState;
    PortState;
    FileState;
    FileSlashState;
    FileHostState;
    PathStartState;
    PathState;
    CannotBeABaseURLPathState;
    QueryState;
    FragmentState;
}


enum StateMachineResult {
    Failure;
    Terminate;
    Continue;
}


class BasicURLParser {
    var validationError:ValidationError;
    var stateOverride:Null<BasicURLParserState>;
    var state:BasicURLParserState;
    var input:String;
    var url:URLRecord;
    var base:Null<URLRecord>;
    var encoding:String;
    var buffer:CodePointBuffer;
    var atFlag:Bool = false;
    var bracketFlag:Bool = false;
    var passwordTokenSeen = false;
    var pointer:StringPointer;

    // for debugging use:
    @:allow(plumekit)
    var rawInput(default, null):String;

    public function new(input:String, ?base:URLRecord,
            ?encodingOverride:String, ?url:URLRecord,
            ?stateOverride:BasicURLParserState) {
        validationError = new ValidationError();

        // trace('URL input=$input');

        rawInput = input;
        initInputAndURL(input, url);
        initState(stateOverride);

        this.base = base;

        initEncoding(encodingOverride);

        buffer = new CodePointBuffer();
        pointer = new StringPointer(this.input);
    }

    function initInputAndURL(input:String, url:URLRecord) {
        if (url == null) {
            url = new URLRecord();

            var newInput = input.trimPredicate(CodePointTools.isC0ControlOrSpace);

            if (newInput != input) {
                input = newInput;
                validationError.set();
            }
        }

        var newInput = input.replacePredicate(CodePointTools.isASCIITabOrNewline, "");

        if (newInput != input) {
            input = newInput;
            validationError.set();
        }

        this.input = input;
        this.url = url;
    }

    function initState(?stateOverride:BasicURLParserState) {
        this.stateOverride = stateOverride;

        if (stateOverride != null) {
            state = stateOverride;
        } else {
            state = SchemeStartState;
        }
    }

    function initEncoding(?encodingOverride:String) {
        this.encoding = "UTF-8";

        if (encodingOverride != null) {
            this.encoding = Registry.getOutputEncodingName(encodingOverride);
        }
    }

    public function parse():ParserResult<URLRecord> {
        while (true) {
            // trace('Pointer = ${pointer.index} ${pointer.c.toNativeString()} State = $state');
            var result = runStateMachine();

            switch result {
                case Failure:
                    return Failure;
                case Terminate:
                    return Result(url);
                case Continue:
                    // pass
            }

            if (pointer.isEOF()) {
                break;
            } else {
                pointer.increment(1);
            }
        }

        return Result(url);
    }

    function runStateMachine():StateMachineResult {
        switch state {
            case SchemeStartState:
                return runSchemeStartState();
            case SchemeState:
                return runSchemeState();
            case NoSchemeState:
                return runNoSchemeState();
            case SpecialRelativeOrAuthorityState:
                return runSpecialRelativeOrAuthorityState();
            case PathOrAuthorityState:
                return runPathOrAuthorityState();
            case RelativeState:
                return runRelativeState();
            case RelativeSlashState:
                return runRelativeSlashState();
            case SpecialAuthoritySlashesState:
                return runSpecialAuthoritySlashesState();
            case SpecialAuthorityIgnoreSlashesState:
                return runSpecialAuthorityIgnoreSlashesState();
            case AuthorityState:
                return runAuthorityState();
            case HostState | HostnameState:
                return runHostAndHostnameState();
            case PortState:
                return runPortState();
            case FileState:
                return runFileState();
            case FileSlashState:
                return runFileSlashState();
            case FileHostState:
                return runFileHostState();
            case PathStartState:
                return runPathStartState();
            case PathState:
                return runPathState();
            case CannotBeABaseURLPathState:
                return runCannotBeABaseURLPathState();
            case QueryState:
                return runQueryState();
            case FragmentState:
                return runFragmentState();
        }
    }

    function runSchemeStartState() {
        if (pointer.c.isASCIIAlpha()) {
            buffer.push(pointer.c.toASCIILowercase());
            state = SchemeState;
        } else if (stateOverride == null) {
            state = NoSchemeState;
            pointer.increment(-1);
        } else {
            validationError.set();
            return Failure;
        }

        return Continue;
    }

    function runSchemeState() {
        if (pointer.c.isASCIIAlphanumeric() || pointer.c.isAnyCodePoint("+-.")) {
            buffer.push(pointer.c.toASCIILowercase());

        } else if (pointer.c == ":".code) {
            return runSchemeStateColon();

        } else if (stateOverride == null) {
            buffer.clear();
            state = NoSchemeState;
            pointer.reset();
        } else {
            validationError.set();
            return Failure;
        }

        return Continue;
    }

    function runSchemeStateColon() {
        var bufferText = buffer.toString();

        if (stateOverride != null) {
            if ((
                SpecialScheme.schemes.contains(url.scheme)
                    && !SpecialScheme.schemes.contains(bufferText))
                || (!SpecialScheme.schemes.contains(url.scheme)
                    && SpecialScheme.schemes.contains(bufferText))
                || ((url.includesCredentials() || url.port != None)
                    && bufferText == "file")
                || (url.scheme == "file" &&
                    (url.host == EmptyHost || url.host == Null))
            ) {
                return Terminate;
            }
        }

        url.scheme = bufferText;

        if (stateOverride != null) {
            if (url.isDefaultPort()) {
                url.port = None;
            }

            return Terminate;
        }

        buffer.clear();

        if (url.scheme == "file") {
            if (!pointer.remaining.startsWith("//")) {
                validationError.set();
            }

            state = FileState;
        } else if (url.isSpecial() && base != null && base.scheme == url.scheme) {
            state = SpecialRelativeOrAuthorityState;
        } else if (url.isSpecial()) {
            state = SpecialAuthoritySlashesState;
        } else if (pointer.remaining.startsWith("/")) {
            state = PathOrAuthorityState;
            pointer.increment(1);
        } else {
            url.cannotBeABaseURL = true;
        }

        return Continue;
    }

    function runNoSchemeState() {
        if (base == null || (base.cannotBeABaseURL && pointer.c != "#".code)) {
            validationError.set();
            return Failure;
        } else if (base.cannotBeABaseURL && pointer.c == "#".code) {
            url.scheme = base.scheme;
            url.path = base.path.copy();
            url.query = base.query;
            url.fragment = Some("");
            url.cannotBeABaseURL = true;
            state = FragmentState;
        } else if (base.scheme != "file") {
            state = RelativeState;
            pointer.increment(-1);
        } else {
            state = FileState;
            pointer.increment(-1);
        }

        return Continue;
    }

    function runSpecialRelativeOrAuthorityState() {
        if (pointer.c == "/".code && pointer.remaining.startsWith("/")) {
            state = SpecialAuthorityIgnoreSlashesState;
            pointer.increment(1);
        } else {
            validationError.set();
            state = RelativeState;
            pointer.increment(-1);
        }

        return Continue;
    }

    function runPathOrAuthorityState() {
        if (pointer.c == "/".code) {
            state = AuthorityState;
        } else {
            state = PathState;
            pointer.increment(-1);
        }

        return Continue;
    }

    function runRelativeState() {
        url.scheme = base.scheme;

        switch pointer.c {
            case INT_NULL:
                url.username = base.username;
                url.password = base.password;
                url.host = base.host;
                url.port = base.port;
                url.path = base.path.copy();
                url.query = base.query;
            case "/".code:
                state = RelativeSlashState;
            case "?".code:
                url.username = base.username;
                url.password = base.password;
                url.host = base.host;
                url.port = base.port;
                url.path = base.path.copy();
                url.query = Some("");
                state = QueryState;
            case "#".code:
                url.username = base.username;
                url.password = base.password;
                url.host = base.host;
                url.port = base.port;
                url.path = base.path.copy();
                url.query = base.query;
                url.fragment = Some("");
                state = FragmentState;
            default:
                if (url.isSpecial() && pointer.c == "\\".code) {
                    validationError.set();
                    state = RelativeSlashState;
                } else {
                    url.username = base.username;
                    url.password = base.password;
                    url.host = base.host;
                    url.port = base.port;
                    url.path = base.path.copy();
                    url.path.pop();

                    state = PathState;
                    pointer.increment(-1);
                }
        }

        return Continue;
    }

    function runRelativeSlashState() {
        if (url.isSpecial() && pointer.c.isAnyCodePoint("/\\")) {
            if (pointer.c == "\\".code) {
                validationError.set();
            }

            state = SpecialAuthorityIgnoreSlashesState;
        } else if (pointer.c == "/".code) {
            state = AuthorityState;
        } else {
            url.username = base.username;
            url.password = base.password;
            url.host = base.host;
            url.port = base.port;
            state = PathState;
            pointer.increment(-1);
        }

        return Continue;
    }

    function runSpecialAuthoritySlashesState() {
        if (pointer.c == "/".code && pointer.remaining.startsWith("/")) {
            state = SpecialAuthorityIgnoreSlashesState;
            pointer.increment(1);
        } else {
            validationError.set();
            state = SpecialAuthorityIgnoreSlashesState;
            pointer.increment(-1);
        }

        return Continue;
    }

    function runSpecialAuthorityIgnoreSlashesState() {
        if (!pointer.c.isAnyCodePoint("/\\")) {
            state = AuthorityState;
            pointer.increment(-1);
        } else {
            validationError.set();
        }

        return Continue;
    }

    function runAuthorityState() {
        if (pointer.c == "@".code) {
            validationError.set();

            if (atFlag) {
                buffer.prependString("%40");
            }

            atFlag = true;

            for (codePoint in buffer) {
                if (codePoint == ":".code && !passwordTokenSeen) {
                    passwordTokenSeen = true;
                    continue;
                }

                var encodedCodePoints = PercentEncoder.utf8PercentEncode(
                    codePoint, PercentEncodeSet.userinfo);

                if (passwordTokenSeen) {
                    url.password += encodedCodePoints;
                } else {
                    url.username += encodedCodePoints;
                }
            }

            buffer.clear();
        } else if (
                (pointer.isEOF() || pointer.c.isAnyCodePoint("/?#"))
                || url.isSpecial() && pointer.c == "\\".code) {
            if (atFlag && buffer.isEmpty()) {
                validationError.set();
                return Failure;
            }

            pointer.increment(-(buffer.length + 1));
            buffer.clear();
            state = HostState;
        } else {
            buffer.push(pointer.c);
        }

        return Continue;
    }

    function runHostAndHostnameState() {
        if (stateOverride != null && url.scheme == "file") {
            pointer.increment(-1);
            state = FileHostState;
        } else if (pointer.c == ":".code && !bracketFlag) {
            if (buffer.isEmpty()) {
                validationError.set();
                return Failure;
            }

            var result = HostParser.parse(buffer.toString(), validationError, !url.isSpecial());
            var host;

            switch result {
                case Failure:
                    return Failure;
                case Result(host_):
                    host = host_;
            }

            url.host = host;
            buffer.clear();
            state = PortState;

            if (stateOverride != null && stateOverride == HostnameState) {
                return Terminate;
            }
        } else if (pointer.isEOF() || pointer.c.isAnyCodePoint("/?#")
                || (url.isSpecial() && pointer.c == "\\".code)) {
            pointer.increment(-1);

            if (url.isSpecial() && buffer.isEmpty()) {
                validationError.set();
                return Failure;
            } else if (stateOverride != null && buffer.isEmpty()
                    && (url.includesCredentials() || url.port != None)) {
                validationError.set();
                return Terminate;
            }

            var result = HostParser.parse(buffer.toString(), validationError, !url.isSpecial());
            var host;

            switch result {
                case Failure: return Failure;
                case Result(host_): host = host_;
            }

            url.host = host;
            buffer.clear();
            state = PathStartState;

            if (stateOverride != null) {
                return Terminate;
            }
        } else {
            if (pointer.c == "[".code) {
                bracketFlag = true;
            }
            if (pointer.c == "]".code) {
                bracketFlag = false;
            }

            buffer.push(pointer.c);
        }

        return Continue;
    }

    function runPortState() {
        if (pointer.c.isASCIIDigit()) {
            buffer.push(pointer.c);
        } else if (pointer.isEOF() || pointer.c.isAnyCodePoint("/?#")
                || (url.isSpecial() && pointer.c == "\\".code)
                || stateOverride != null) {
            if (!buffer.isEmpty()) {
                var port = IntParser.parseInt(buffer.toString(), 10);

                if (port > 65535) {
                    validationError.set();
                    return Failure;
                }

                url.port = Some(port);
                if (url.isDefaultPort()) {
                    url.port = None;
                }

                buffer.clear();
            }

            if (stateOverride != null) {
                return Terminate;
            }

            state = PathStartState;
            pointer.increment(-1);
        } else {
            validationError.set();
            return Failure;
        }

        return Continue;
    }

    function runFileState() {
        url.scheme = "file";

        if (pointer.c.isAnyCodePoint("/\\")) {
            if (pointer.c == "\\".code) {
                validationError.set();
            }

            state = FileSlashState;

        } else if (base != null && base.scheme == "file") {
            switch pointer.c {
                case INT_NULL:
                    url.host = base.host;
                    url.path = base.path.copy();
                    url.query = base.query;
                case "?".code:
                    url.host = base.host;
                    url.path = base.path.copy();
                    url.query = Some("");
                    state = QueryState;
                case "#".code:
                    url.host = base.host;
                    url.path = base.path.copy();
                    url.query = base.query;
                    url.fragment = Some("");
                    state = FragmentState;
                default:
                    if (!pointer.substring.startsWithWindowsDriveLetter()) {
                        url.host = base.host;
                        url.path = base.path.copy();
                        url.shortenPath();
                    } else {
                        validationError.set();
                    }

                    state = PathState;
                    pointer.increment(-1);
            }

        } else {
            state = PathState;
            pointer.increment(-1);
        }

        return Continue;
    }

    function runFileSlashState() {
        if (pointer.c.isAnyCodePoint("/\\")) {
            if (pointer.c == "\\".code) {
                validationError.set();
            }

            state = FileHostState;
        } else {
            if (base != null && base.scheme == "file"
                    && !pointer.substring.startsWithWindowsDriveLetter()) {
                if (base.path.get(0).isNormalizedWindowsDriveLetter()) {
                    url.path.push(base.path.get(0));
                } else {
                    url.host = base.host;
                }
            }

            state = PathState;
        }

        return Continue;
    }

    function runFileHostState() {
        if (pointer.isEOF() || pointer.c.isAnyCodePoint("/\\?#")) {
            pointer.increment(-1);

            if (stateOverride == null && buffer.toString().isWindowsDriveLetter()) {
                validationError.set();
                state = PathState;
            } else if (buffer.isEmpty()) {
                url.host = Host.EmptyHost;

                if (stateOverride != null) {
                    return Terminate;
                }

                state = PathStartState;
            } else {
                var result = HostParser.parse(buffer.toString(), validationError, !url.isSpecial());
                var host;

                switch result {
                    case Failure: return Failure;
                    case Result(host_): host = host_;
                }

                switch host {
                    case Host.OpaqueHost(hostString):
                        if (hostString == "localhost") {
                            host = Host.EmptyHost;
                        }
                    default: // pass
                }

                url.host = host;

                if (stateOverride != null) {
                    return Terminate;
                }

                buffer.clear();
                state = PathStartState;
            }
        } else {
            buffer.push(pointer.c);
        }

        return Continue;
    }

    function runPathStartState() {
        if (url.isSpecial()) {
            if (pointer.c == "\\".code) {
                validationError.set();
            }

            state = PathState;

            if(!pointer.c.isAnyCodePoint("/\\")) {
                pointer.increment(-1);
            }
        } else if (stateOverride == null && pointer.c == "?".code) {
            url.query = Some("");
            state = QueryState;
        } else if (stateOverride == null && pointer.c == "#".code) {
            url.fragment = Some("");
            state = FragmentState;
        } else if (!pointer.isEOF()) {
            state = PathState;

            if (pointer.c != "/".code) {
                pointer.increment(-1);
            }
        }

        return Continue;
    }

    function runPathState() {
        if ((pointer.isEOF() || pointer.c == "/".code)
                || (url.isSpecial() && pointer.c == "\\".code)
                || (stateOverride == null && (pointer.c == "?".code || pointer.c == "#".code))) {
            if (url.isSpecial() && pointer.c == "\\".code) {
                validationError.set();
            }

            if (buffer.toString().isDoubleDotPathSegment()) {
                url.path.pop();

                if (pointer.c != "/".code || !url.isSpecial() && pointer.c != "\\".code) {
                    url.path.push("");
                }
            } else if (buffer.toString().isSingleDotPathSegment()
                    && pointer.c != "/".code || !url.isSpecial() && pointer.c != "\\".code) {
                url.path.push("");
            } else if (!buffer.toString().isSingleDotPathSegment()) {
                if (url.scheme == "file" && url.path.isEmpty()
                        && buffer.toString().isWindowsDriveLetter()) {
                    if (url.host != Host.EmptyHost || url.host == Host.Null) {
                        validationError.set();
                        url.host = Host.EmptyHost;
                    }

                    buffer.set(1, ":".code);
                }

                url.path.push(buffer.toString());
            }

            buffer.clear();

            if (url.scheme == "file"
                    && (pointer.isEOF() || pointer.c.isAnyCodePoint("?#"))) {
                while (url.path.length > 1 && url.path.get(0) == "") {
                    validationError.set();
                    url.path.shift();
                }
            }

            if (pointer.c == "?".code) {
                url.query = Some("");
                state = QueryState;
            }

            if (pointer.c == "#".code) {
                url.fragment = Some("");
                state = FragmentState;
            }
        } else {
            if (!pointer.c.isURLCodePoint() && pointer.c != "%".code) {
                validationError.set();
            }

            if (pointer.c == "%".code && !pointer.remaining.startsWithTwoHexDigits()) {
                    validationError.set();
            }

            buffer.appendString(
                PercentEncoder.utf8PercentEncode(pointer.c, PercentEncodeSet.path)
            );
        }

        return Continue;
    }

    function runCannotBeABaseURLPathState() {
        if (pointer.c == "?".code) {
            url.query = Some("");
            state = QueryState;
        } else if (pointer.c == "#".code) {
            url.fragment = Some("");
            state = FragmentState;
        } else {
            if (!pointer.isEOF() && !pointer.c.isURLCodePoint() && pointer.c != "%".code) {
                validationError.set();
            }

            if (pointer.c == "%".code && !pointer.remaining.startsWithTwoHexDigits()) {
                validationError.set();
            }

            if (!pointer.isEOF()) {
                var encoded = PercentEncoder.utf8PercentEncode(pointer.c, PercentEncodeSet.c0Control);
                url.path.set(0, url.path.get(0) + encoded);
            }
        }

        return Continue;
    }

    function runQueryState() {
        if (encoding != "UTF-8" && (!url.isSpecial()
                || url.scheme == "ws"
                || url.scheme == "wss")) {
            encoding = "UTF-8";
        }

        if (stateOverride == null && pointer.c == "#".code) {
            url.fragment = Some("");
            state = FragmentState;
        } else if (!pointer.isEOF()) {
            if (!pointer.c.isURLCodePoint() && !pointer.remaining.startsWithTwoHexDigits()) {
                validationError.set();
            }

            var bytes = SpecHook.encode(pointer.c.toNativeString(), encoding);

            if (bytes.startsWithByte("&".code, "#".code) && bytes.endsWithByte(";".code)) {
                var decoded = bytes.sub(2, bytes.length - 3).isomorphicDecode();

                url.query = Some(url.query.getSome() + '%26%23$decoded%3B');
            } else {
                runQueryStateForEachByte(bytes);
            }
        }

        return Continue;
    }

    function runQueryStateForEachByte(bytes:Bytes) {
        for (index in 0...bytes.length) {
            var byte = bytes.get(index);

            if (byte < "!".code
                    || byte > "~".code
                    || byte == "\"".code
                    || byte == "#".code
                    || byte == "<".code
                    || byte == ">".code
                    || (byte == "'".code && url.isSpecial())) {
                url.query = Some(
                    url.query.getSome() + PercentEncoder.percentEncode(byte));
            } else {
                url.query = Some(url.query.getSome() + byte.toNativeString());
            }
        }
    }

    function runFragmentState() {
        switch pointer.c {
            case INT_NULL:
                // do nothing
            case 0:
                validationError.set();
            default:
                if (!pointer.c.isURLCodePoint() && pointer.c != "%".code) {
                    validationError.set();
                }

                if (pointer.c == "%".code && !pointer.remaining.startsWithTwoHexDigits()) {
                    validationError.set();
                }

                url.fragment = Some(
                    url.fragment.getSome()
                    + PercentEncoder.utf8PercentEncode(pointer.c, PercentEncodeSet.fragment));
        }
        return Continue;
    }
}
