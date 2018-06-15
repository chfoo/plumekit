package plumekit.text.codec;


enum Result {
    Finished;
    Token(token:Int);
    Tokens(tokens:Array<Int>);
    Error(codePoint:Int);
    Continue;
}
