package plumekit.net;

import callnest.Task;
import callnest.TaskDefaults;
import callnest.TaskSource;
import haxe.Timer;
import plumekit.net.NetException.TimeoutException;
import sys.net.Socket;


@:structInit
private class Entry {
    public var taskSource:TaskSource<Socket>;
    public var timestamp:Float;
    public var timeout:Float;
}


class SelectDispatcher {
    static var _instance:SelectDispatcher;

    public var pendingCount(get, never):Int;

    var readArray:Array<Socket>;
    var writeArray:Array<Socket>;
    var otherArray:Array<Socket>;
    var readEntries:Map<Socket,Entry>;
    var writeEntries:Map<Socket,Entry>;
    var otherEntries:Map<Socket,Entry>;
    var yieldInterval:Float;
    var timeout:Float;

    public function new(yieldInterval:Float = 1.0) {
        timeout = this.yieldInterval = yieldInterval;
        readArray = [];
        writeArray = [];
        otherArray = [];
        readEntries = new Map();
        writeEntries = new Map();
        otherEntries = new Map();
    }

    public static function instance():SelectDispatcher {
        if (_instance == null) {
            _instance = new SelectDispatcher();
        }

        return _instance;
    }

    static inline function floatOrInfinite(?value:Float):Float {
        return value != null ? value : Math.POSITIVE_INFINITY;
    }

    function get_pendingCount():Int {
        return readArray.length + writeArray.length + otherArray.length;
    }

    function updateTimeout(timeout:Float) {
        this.timeout = Math.min(this.timeout, timeout);
    }

    public function waitRead(socket:Socket, ?timeout:Float):Task<Socket> {
        timeout = floatOrInfinite(timeout);
        updateTimeout(timeout);
        readArray.push(socket);
        return addEntry(readEntries, socket, timeout);
    }

    public function waitWrite(socket:Socket, ?timeout:Float):Task<Socket> {
        timeout = floatOrInfinite(timeout);
        updateTimeout(timeout);
        writeArray.push(socket);
        return addEntry(writeEntries, socket, timeout);
    }

    public function waitOther(socket:Socket, ?timeout:Float):Task<Socket> {
        timeout = floatOrInfinite(timeout);
        updateTimeout(timeout);
        otherArray.push(socket);
        return addEntry(otherEntries, socket, timeout);
    }

    function addEntry(map:Map<Socket,Entry>, socket:Socket, timeout:Float):Task<Socket> {
        if (!map.exists(socket)) {
            map.set(socket, {
                taskSource: TaskDefaults.newTaskSource(),
                timestamp: Timer.stamp(),
                timeout: timeout
            });
        }

        return map.get(socket).taskSource.task;
    }

    public function processOnce() {
        // trace('select read=${readArray.length} write=${writeArray.length}');
        var result = Socket.select(readArray, writeArray, otherArray, timeout);
        // trace('result read=${result.read.length} write=${result.write.length}');

        checkAndExpireSockets(readArray, readEntries);
        checkAndExpireSockets(writeArray, writeEntries);
        checkAndExpireSockets(otherArray, otherEntries);

        for (socket in result.read) {
            readArray.remove(socket);
            completeEntry(readEntries, socket);
        }

        for (socket in result.write) {
            writeArray.remove(socket);
            completeEntry(writeEntries, socket);
        }

        for (socket in result.others) {
            otherArray.remove(socket);
            completeEntry(otherEntries, socket);
        }

        if (readArray.length == 0 && writeArray.length == 0
                && otherArray.length == 0) {
            timeout = yieldInterval;
        }
    }

    function checkAndExpireSockets(socketArray:Array<Socket>,
            entryMap:Map<Socket,Entry>) {
        var timestampNow = Timer.stamp();

        for (socket in socketArray.copy()) {
            var entry = entryMap.get(socket);

            if (timestampNow - entry.timestamp > entry.timeout) {
                socketArray.remove(socket);
                entryMap.remove(socket);
                expireEntry(entry);
                socket.close();
            }
        }
    }

    function completeEntry(map:Map<Socket,Entry>, socket:Socket) {
        if (!map.exists(socket)) {
            return;
        }

        var entry = map.get(socket);
        map.remove(socket);

        if (entry.taskSource.task.isCanceled) {
            return;
        }

        entry.taskSource.setResult(socket);
    }

    function expireEntry(entry:Entry) {
        var exception = new TimeoutException(
            'Socket operation did not complete within ${entry.timeout} seconds');
        entry.taskSource.setException(exception);
    }
}
