package plumekit.protocol.gopher;

import plumekit.stream.ReadScanResult;
import haxe.ds.Option;
import callnest.Task;
import haxe.io.Bytes;
import plumekit.Exception.ValueException;
import plumekit.stream.PipeTransfer;
import plumekit.stream.Sink;
import plumekit.stream.Source;
import plumekit.stream.TextReader;
import plumekit.stream.TextWriter;
import plumekit.protocol.gopher.GopherException;

using callnest.TaskTools;
using plumekit.stream.PipeTools;
using StringTools;


class ProtocolReaderWriter {
    static inline var ENCODING_NAME = "Windows-1252";
    static var NEWLINE = Bytes.ofString("\r\n");
    static inline var LAST_LINE = ".\r\n";

    var source:Source;
    var sink:Sink;
    var textReader:TextReader;
    var textWriter:TextWriter;

    public function new(source:Source, sink:Sink) {
        this.source = source;
        this.sink = sink;
        textReader = new TextReader(source, ENCODING_NAME);
        textWriter = new TextWriter(sink, ENCODING_NAME);
    }

    static function throwIfNewlines(text:String) {
        if (text.indexOf("\n") >= 0 || text.indexOf("\r") >= 0) {
            throw new ValueException("Newlines found in string.");
        }
    }

    public function readSelector():Task<String> {
        return textReader.readLine(false).continueWith(function (task) {
            switch (task.getResult()) {
                case ReadScanResult.Success(line):
                    return TaskTools.fromResult(line);
                case ReadScanResult.Incomplete(line):
                    throw new BadRequestException();
                case ReadScanResult.OverLimit(line):
                    throw new GopherException("Line too long");
            }
        });
    }

    public function writeSelector(selector:String):Task<String> {
        throwIfNewlines(selector);

        return textWriter.write('$selector\r\n').continueWith(function (task) {
            task.getResult();
            return TaskTools.fromResult(selector);
        });
    }

    public function readDirectoryEntity():Task<Option<DirectoryEntity>> {
        return textReader.readLine(true).continueWith(readDirectoryCallback);
    }

    function readDirectoryCallback(task:Task<ReadScanResult<String>>) {
        switch (task.getResult()) {
            case ReadScanResult.Success(line):
                if (line.startsWith(".")) {
                    return TaskTools.fromResult(None);
                } else {
                    return TaskTools.fromResult(
                        Some(DirectoryEntity.parseString(line)));
                }
            case ReadScanResult.Incomplete(line):
                return TaskTools.fromResult(None);
            case ReadScanResult.OverLimit(line):
                throw new GopherException("Line too long");
        }
    }

    public function writeDirectoryEntity(directoryEntity:DirectoryEntity)
            :Task<DirectoryEntity> {
        return textWriter.write(directoryEntity.toString())
            .continueWith(function (task) {
                task.getResult();

                return TaskTools.fromResult(directoryEntity);
            });
    }

    public function getFile(textMode:Bool = false):Source {
        if (textMode) {
            return source.withTransform(new TextFileUnescaper());
        } else {
            return source;
        }
    }

    public function putFile(file:Source, textMode:Bool = false):PipeTransfer {
        if (textMode) {
            return new PipeTransfer(
                file.withTransform(new TextFileEscaper()), sink);
        } else {
            return new PipeTransfer(file, sink);
        }
    }

    public function writeLastLine():Task<String> {
        return textWriter.write(LAST_LINE).thenResult(LAST_LINE);
    }
}
