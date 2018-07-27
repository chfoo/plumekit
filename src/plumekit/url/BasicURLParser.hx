package plumekit.url;

import haxe.io.BytesBuffer;
import unifill.InternalEncoding;
import haxe.ds.Option;
import plumekit.text.codec.Registry;
import plumekit.text.CodePointTools.INT_NULL;
import plumekit.text.CodePointBuffer;
import plumekit.url.ParserResult;

using plumekit.text.StringTextTools;
using plumekit.text.CodePointTools;
using unifill.Unifill;
using commonbox.utils.OptionTools;
using StringTools;
using plumekit.url.ParserTools;


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
    Continue;
}


class BasicURLParser {
    var validationError:ValidationError;
    var stateOverride:Null<BasicURLParserState>;
    var state:BasicURLParserState;
    var url:URLRecord;
    var base:Null<URLRecord>;
    var encoding:String;
    var buffer:CodePointBuffer;
    var atFlag:Bool = false;
    var bracketFlag:Bool = false;
    var passwordTokenSeen = false;
    var pointer:StringPointer;

    public function new(input:String, ?base:URLRecord,
            ?encodingOverride:String, ?url:URLRecord,
            ?stateOverride:BasicURLParserState) {
        validationError = new ValidationError();

        if (url == null) {
            url = new URLRecord();

            var newInput = input.trimPredicate(CodePointTools.isC0ControlOrSpace);

            if (newInput != input) {
                input = newInput;
                validationError.set();
            }
        }

        this.url = url;

        var newInput = input.replacePredicate(CodePointTools.isASCIITabOrNewline, "");

        if (newInput != input) {
            input = newInput;
            validationError.set();
        }

        this.stateOverride = stateOverride;

        if (stateOverride != null) {
            state = stateOverride;
        } else {
            state = SchemeStartState;
        }

        this.base = base;
        this.encoding = "UTF-8";

        if (encodingOverride != null) {
            this.encoding = Registry.getOutputEncodingName(encodingOverride);
        }

        buffer = new CodePointBuffer();
        pointer = new StringPointer(input);
    }

    public function parse():ParserResult<URLRecord> {
        while (true) {
            var result = runStateMachine();

            switch result {
                case Failure:
                    return Failure;
                case Continue:
                    // pass
            }

            if (pointer.c == INT_NULL) {
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
        if (pointer.c.isASCIIAlphanumeric()
                || pointer.c == "+".code
                || pointer.c == "-".code
                || pointer.c == ".".code) {
            buffer.push(pointer.c.toASCIILowercase());

        } else if (pointer.c == ":".code) {
            if (stateOverride != null) {
                var bufferText = buffer.toString();

                if ((
                    SpecialScheme.schemes.contains(url.scheme)
                        && !SpecialScheme.schemes.contains(bufferText))
                    || (!SpecialScheme.schemes.contains(url.scheme)
                        && SpecialScheme.schemes.contains(bufferText))
                    || ((url.includesCredentials() || url.port != null)
                        && bufferText == "file")
                    || (url.scheme == "file" &&
                        (url.host == EmptyHost || url.host == Null))
                ) {
                    return Continue;
                }

                url.scheme = bufferText;
            }

            if (stateOverride != null) {
                if (SpecialScheme.defaultPorts.get(url.scheme).someEquals(url.port.getSome())) {
                    url.port = None;
                    return Continue;
                }
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
        if (url.isSpecial()
                && (pointer.c == "/".code || pointer.c == "\\".code)) {
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
        if (pointer.c != "/".code && pointer.c != "\\".code) {
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
                (pointer.c == INT_NULL
                    || pointer.c == "/".code
                    || pointer.c == "?".code
                    || pointer.c == "#".code)
                ||
                (url.isSpecial() && pointer.c == "\\".code)) {
            if (atFlag && buffer.isEmpty()) {
                validationError.set();
                return Failure;
            }

            pointer.increment(buffer.length + 1);
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

            var host = HostParser.parse(buffer.toString(), validationError, true);
        }

        throw "not implemented";
        return Continue;
    }

    function runPortState() {
        throw "not implemented";
        return Continue;
    }

    function runFileState() {
        throw "not implemented";
        return Continue;
    }

    function runFileSlashState() {
        throw "not implemented";
        return Continue;
    }

    function runFileHostState() {
        throw "not implemented";
        return Continue;
    }

    function runPathStartState() {
        throw "not implemented";
        return Continue;
    }

    function runPathState() {
        if ((pointer.c == INT_NULL || pointer.c == "/".code)
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
                    && (pointer.c == INT_NULL || pointer.c == "?".code
                    || pointer.c == "#".code)) {
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
            if (pointer.c != INT_NULL && !pointer.c.isURLCodePoint() && pointer.c != "%".code) {
                validationError.set();
            }

            if (pointer.c == "%".code && !pointer.remaining.startsWithTwoHexDigits()) {
                validationError.set();
            }

            if (pointer.c != INT_NULL) {
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
        } else if (pointer.c != INT_NULL) {
            if (!pointer.c.isURLCodePoint() && !pointer.remaining.startsWithTwoHexDigits()) {
                validationError.set();
            }

            var encoder = Registry.getSpecEncoder(encoding);
            var bytes = encoder.encode(InternalEncoding.fromCodePoint(pointer.c));

            if (bytes.startsWithByte("&".code, "#".code) && bytes.endsWithByte(";".code)) {
                var decoded = bytes.sub(2, bytes.length - 3).isomorphicDecode();

                url.query = Some(url.query.getSome() + '%26%23$decoded%3B');
            } else {
                for (index in 0...bytes.length) {
                    var byte = bytes.get(index);

                    if (byte < "!".code
                            || byte > "~".code
                            || byte == "\"".code
                            || byte == "#".code
                            || byte == "<".code
                            || byte == ">".code
                            || (byte == "'".code && url.isSpecial())) {
                        url.query = Some(url.query.getSome() + PercentEncoder.percentEncode(byte));
                    } else {
                        url.query = Some(url.query.getSome() + InternalEncoding.fromCodePoint(byte));
                    }
                }
            }
        }

        return Continue;
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
