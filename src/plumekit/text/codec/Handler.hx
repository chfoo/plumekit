package plumekit.text.codec;


interface Handler {
    public function process(stream:Stream, token:Int):Result;
}
