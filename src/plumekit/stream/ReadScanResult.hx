package plumekit.stream;


enum ReadScanResult<T> {
    Success(data:T);
    OverLimit(data:T);
    Incomplete(data:T);
}
