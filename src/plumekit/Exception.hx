package plumekit;


class Exception extends haxe.Exception {
    override function toString():String {
        return '[${Type.getClassName(Type.getClass(this))} ${message}]';
    }
}


class SystemException extends Exception {
}


class OutOfBoundsException extends Exception {
}


class ValueException extends Exception {
}


class NotImplementedException extends Exception {
}
