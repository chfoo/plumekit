package plumekit.test.net.cases;

import plumekit.stream.Sink;
import plumekit.stream.Source;
import utest.Assert;
import plumekit.stream.ReadResult;
import haxe.io.Bytes;
import callnest.VoidReturn;
import plumekit.stream.StreamWriter;
import plumekit.stream.StreamReader;
import plumekit.net.Connection;
import callnest.Task;
import plumekit.eventloop.EventLoop;

using callnest.TaskTools;
using plumekit.TaskTestTools;


class EchoReadWriteTestCase {
    static inline var SOCKET_TIMEOUT = 5.0;

    var reader:StreamReader;
    var writer:StreamWriter;
    var iterationCounter = 0;
    var iterationBytes:Bytes;

    public function new() {
    }

    function setUpServer() {
        throw "not implemented";
    }

    function tearDownServer() {
        throw "not implemented";
    }

    function newEventLoop():EventLoop {
        throw "not implemented";
    }

    function getConnection():Task<Connection> {
        throw "not implemented";
    }

    public function testEcho() {
        var eventLoop = newEventLoop();
        var done = TaskTestTools.startAsync();

        setUpServer();

        getConnection()
            .continueWith(function (task) {
                var connection = task.getResult();

                reader = new StreamReader(connection.source);
                writer = new StreamWriter(connection.sink);

                return echoIteration();
            })
            .onComplete(function (task) {
                tearDownServer();
                task.getResult();
                done();
            })
            .handleException(TaskTestTools.exceptionHandler);

        eventLoop.startTimedTest();
    }

    function echoIteration():Task<VoidReturn> {
        iterationBytes = Bytes.alloc(Std.int(Math.pow(10, iterationCounter)));

        for (index in 0...iterationBytes.length) {
            iterationBytes.set(index, index % 256);
        }

        iterationCounter += 1;

        if (iterationCounter >= 8) {
            return TaskTools.fromResult(VoidReturn.Nothing);
        }

        var writeTask = writer.write(iterationBytes);
        var readTask = reader.read(iterationBytes.length);

        return readTask.continueWith(writeReadCallback.bind(writeTask));
    }

    function writeReadCallback(writeTask:Task<Int>, task:Task<ReadResult<Bytes>>):Task<VoidReturn> {
        var bytesWritten = writeTask.getResult();
        Assert.equals(iterationBytes.length, bytesWritten);

        switch task.getResult() {
            case Success(data):
                Assert.equals(0, iterationBytes.compare(data));
                return echoIteration();
            case Incomplete(data):
                Assert.fail();
                return TaskTools.fromResult(VoidReturn.Nothing);
        }
    }
}


class SysEchoReadWriteTestCase extends EchoReadWriteTestCase {
    var serverConnection:Connection;
    var serverChildConnection:Connection;
    var serverBuffer:Bytes;
    var eventLoop:EventLoop;

    override function setUpServer() {
        serverConnection = eventLoop.newConnection();
        serverConnection.bind("localhost", 0);
        serverConnection.listen(1);
        serverConnection.accept()
            .continueWith(serverAcceptCallback)
            .handleException(TaskTestTools.exceptionHandler);
    }

    function serverAcceptCallback(task:Task<Connection>) {
        serverChildConnection = task.getResult();
        serverBuffer = Bytes.alloc(8192);

        return serverIteration();
    }

    function serverIteration() {
        return serverChildConnection.source.readReady()
            .continueWith(serverReadCallback);
    }

    function serverReadCallback(task:Task<Source>):Task<VoidReturn> {
        var source = task.getResult();
        var result = source.readInto(serverBuffer, 0, serverBuffer.length);

        switch result {
            case Some(bytesRead):
                // trace('read bytes = $bytesRead');
                return serverChildConnection.sink.writeReady()
                    .continueWith(serverWriteCallback.bind(_, bytesRead));
            case None:
                return TaskTools.fromResult(VoidReturn.Nothing);
        }
    }

    function serverWriteCallback(task:Task<Sink>, bytesRead:Int):Task<VoidReturn> {
        var sink = task.getResult();
        sink.write(serverBuffer, 0, bytesRead);
        // trace('wrote bytes = $bytesRead');

        return serverIteration();
    }

    override function tearDownServer() {
        serverConnection.close();
    }

    override function getConnection():Task<Connection> {
        var connection = eventLoop.newConnection();
        var port = serverConnection.hostAddress().port;

        return connection.connect("localhost", port);
    }
}
