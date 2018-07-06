package plumekit.url;


class ValidationError {
    public var value:Bool = false;

    public function new() {
    }

    public function get():Bool {
        return value;
    }

    public function set() {
        value = true;
    }
}
