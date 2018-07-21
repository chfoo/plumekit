package plumekit.url;


enum ParserResult<T> {
    Failure;
    Result(result:T);
}
