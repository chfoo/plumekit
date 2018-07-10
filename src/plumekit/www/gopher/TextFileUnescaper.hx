package plumekit.www.gopher;

using StringTools;


class TextFileUnescaper extends BaseTextFileTransformer {
    override function processStartOfLine(line:String):String {
        if (line.startsWith("..")) {
            line = line.substr(1);
        } else if (line.startsWith(".")) {
            line = "";
            isEOF = true;
        }

        return line;
    }
}
