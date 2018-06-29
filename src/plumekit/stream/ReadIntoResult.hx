package plumekit.stream;


enum ReadIntoResult {
    Success;
    Incomplete(readCount:Int);
}
