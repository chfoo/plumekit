package plumekit.protocol.gopher;

using StringTools;


class TextFileEscaper extends BaseTextFileTransformer {
    override function processStartOfLine(line:String):String {
        if (line.startsWith(".")) {
            line = '.$line';
        }

        return line;
    }
}
