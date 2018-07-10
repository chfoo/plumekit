package plumekit.www.gopher;

import plumekit.stream.ReadScanResult;
import haxe.ds.Option;
import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import plumekit.Exception.ValueException;
import plumekit.stream.PipeTransfer;
import plumekit.stream.Sink;
import plumekit.stream.Source;
import plumekit.stream.TextReader;
import plumekit.stream.TextWriter;
import plumekit.www.gopher.GopherException;

using plumekit.stream.PipeTools;
using StringTools;


class ProtocolReaderWriter {
    static inline var ENCODING_NAME = "Windows-1252";
    static var NEWLINE = Bytes.ofString("\r\n");

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

        return textWriter.write(selector).continueWith(function (task) {
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

    public function getTextFile():Source {
        return source.withTransform(new TextFileUnescaper());
    }

    public function putTextFile(textFile:Source):PipeTransfer {
        return new PipeTransfer(
            source.withTransform(new TextFileEscaper()), sink);
    }

    public function getFile():Source {
        return source;
    }

    public function putFile(file:Source):PipeTransfer {
        return new PipeTransfer(source, sink);
    }
}
