package plumekit.stream;


enum ReadResult<T> {
    Success(data:T);
    Incomplete(data:T);
}
