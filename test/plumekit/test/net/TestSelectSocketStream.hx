package plumekit.test.net;

import utest.Assert;
import callnest.TaskTools;
import haxe.io.Bytes;
import sys.net.Host;
import sys.net.Socket;
import plumekit.net.SelectDispatcher;
import plumekit.net.SelectSocketStream;
import plumekit.eventloop.SelectEventLoop;

using plumekit.eventloop.EventLoopTools;


class TestSelectSocketStream {
    static inline var TEST_TIMEOUT = 10000;
    static inline var LOOP_DURATION = 5.0;
    static inline var SOCKET_TIMEOUT = 5.0;

    public function new() {
    }

    public function testReadWrite() {
        var dispatcher = new SelectDispatcher();
        var eventLoop = new SelectEventLoop(dispatcher);
        var socket = new Socket();
        var stream = new SelectSocketStream(socket, dispatcher);
        var result:Bytes = null;
        var done = Assert.createAsync(function () {
            Assert.notNull(result);
        }, TEST_TIMEOUT);

        socket.setTimeout(SOCKET_TIMEOUT);
        socket.connect(new Host("localhost"), 80);
        socket.setBlocking(false);
        socket.setFastSend(true);

        stream.readTimeout = stream.writeTimeout = SOCKET_TIMEOUT;
        stream.writeReady()
            .continueWith(function (task) {
                task.getResult();

                var bytes = Bytes.ofString("GET /\r\n");
                var bytesWritten = stream.write(bytes, 0, bytes.length);
                Assert.equals(7, bytesWritten);

                return stream.readReady();
            })
            .continueWith(function (task) {
                task.getResult();

                var bytes = Bytes.alloc(1024);
                var bytesRead = stream.readInto(bytes, 0, bytes.length);
                Assert.notEquals(0, bytesRead);

                return TaskTools.fromResult(bytes.sub(0, bytesRead));
            })
            .onComplete(function (task) {
                result = task.getResult();
                stream.close();
                eventLoop.stop();
                done();
            })
            .handleException(exceptionHandler);

        eventLoop.startTimed(LOOP_DURATION);
    }

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
