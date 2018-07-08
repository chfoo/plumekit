package plumekit.stream;

import callnest.Task;
import callnest.TaskTools;
import plumekit.text.codec.Decoder;
import plumekit.text.codec.ErrorMode;
import plumekit.text.codec.Registry;


class TextReader {
    var streamReader:StreamReader;
    var decoder:Decoder;
    var maxBufferSize:Int;
    var chunkSize:Int;
    var isEOF = false;
    var textScanner:TextScanner;

    public function new(source:Source, encoding:String = "utf-8",
            ?errorMode:ErrorMode,
            maxBufferSize:Int = 16384, chunkSize:Int = 8192) {
        Debug.assert(maxBufferSize > 2);
        Debug.assert(chunkSize > 0);

        streamReader = new StreamReader(source);
        decoder = Registry.getDecoder(encoding, errorMode);
        this.maxBufferSize = maxBufferSize;
        this.chunkSize = chunkSize;
        textScanner = new TextScanner();  // soft limit, don't pass maxBufferSize
    }

    public function read(?amount:Int):Task<String> {
        amount = amount != null ? amount : -1;

        if (amount >= 0) {
            return readAmount(amount);
        } else {
            return readAll();
        }
    }

    function readAmount(amount:Int):Task<String> {
        if (!textScanner.isEmpty()) {
            return TaskTools.fromResult(textScanner.shiftString(amount));
        }

        return streamReader.readOnce(amount).continueWith(function (task) {
            var bytes = task.getResult();
            var incremental = amount != 0 && bytes.length > 0;
            return TaskTools.fromResult(decoder.decode(bytes, incremental));
        });
    }

    public function readAll():Task<String> {
        var textBuffer = new StringBuf();

        textBuffer.add(textScanner.shiftString());

        return streamReader.readAll().continueWith(function (task) {
            var bytes = task.getResult();
            var text = decoder.decode(bytes);
            textBuffer.add(text);

            return TaskTools.fromResult(textBuffer.toString());
        });
    }

    public function readLine(keepEnd:Bool = false):Task<ReadScanResult<String>> {
        switch (textScanner.scanLine(keepEnd)) {
            case Some(text):
                return TaskTools.fromResult(ReadScanResult.Success(text));
            case None:
                return readLineIteration(keepEnd);
        }
    }

    function readLineIteration(keepEnd:Bool):Task<ReadScanResult<String>> {
        return fillBuffer().continueWith(function (task) {
            var text = task.getResult();

            if (text == "") {
                return TaskTools.fromResult(
                    ReadScanResult.Incomplete(textScanner.shiftString()));
            } else if (textScanner.bufferLength >= maxBufferSize) {
                // Leave a character in the buffer because it might
                // break in between a deliminator
                var amount = textScanner.bufferLength - 1;
                return TaskTools.fromResult(
                    ReadScanResult.OverLimit(textScanner.shiftString(amount)));
            }

            return readLine(keepEnd);
        });
    }

    function fillBuffer():Task<String> {
        return streamReader.read(chunkSize).continueWith(function (task) {
            var text;

            switch (task.getResult()) {
                case ReadResult.Success(bytes):
                    text = decoder.decode(bytes, true);
                case ReadResult.Incomplete(bytes):
                    text = decoder.decode(bytes);
                    isEOF = true;
            }

            textScanner.pushString(text);

            if (isEOF) {
                textScanner.setEOF();
            }

            return TaskTools.fromResult(text);
        });
    }
}
