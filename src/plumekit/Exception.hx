package plumekit;


class Exception extends haxe.Exception {
    public static var fullStackString = false;

    override function toString():String {
        if (fullStackString) {
            return super.toString();
        } else {
            return '[${Type.getClassName(Type.getClass(this))} ${message}]';
        }
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
