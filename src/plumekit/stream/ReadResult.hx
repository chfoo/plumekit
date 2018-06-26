package plumekit.stream;

import haxe.io.Bytes;


enum ReadResult {
    Data(data:Bytes);
    Incomplete(data:Bytes);
}
