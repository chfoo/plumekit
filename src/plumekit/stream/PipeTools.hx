package plumekit.stream;


class PipeTools {
    public static function withTransform(source:Source, transformer:Transformer):Source {
        return new TransformStream(source, transformer);
    }
}
