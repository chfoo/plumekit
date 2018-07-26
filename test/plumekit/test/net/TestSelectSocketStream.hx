package plumekit.test.net;

import utest.Assert;
import callnest.TaskTools;
import haxe.io.Bytes;
import sys.net.Host;
import sys.net.Socket;
import plumekit.net.SelectDispatcher;
import plumekit.net.SelectSocketStream;
import plumekit.eventloop.SelectEventLoop;

using plumekit.TaskTestTools;


class TestSelectSocketStream {
    static inline var SOCKET_TIMEOUT = 5.0;

    public function new() {
    }

    public function testManualReadWrite() {
        var dispatcher = new SelectDispatcher();
        var eventLoop = new SelectEventLoop(dispatcher);
        var socket = new Socket();
        var stream = new SelectSocketStream(socket, dispatcher);
        var result:Bytes = null;
        var done = TaskTestTools.startAsync(function () {
            Assert.notNull(result);
        });

        socket.setTimeout(SOCKET_TIMEOUT);
        connectSocket(socket);
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
                switch (stream.readInto(bytes, 0, bytes.length)) {
                    case Some(bytesRead):
                        Assert.notEquals(0, bytesRead);
                        return TaskTools.fromResult(bytes.sub(0, bytesRead));
                    case None:
                        Assert.fail();
                        return TaskTools.fromResult(Bytes.alloc(0));
                }
            })
            .onComplete(function (task) {
                result = task.getResult();
                stream.close();
                eventLoop.stop();
                done();
            })
            .handleException(TaskTestTools.exceptionHandler);

        eventLoop.startTimedTest();
    }

    function connectSocket(socket:Socket) {
        for (port in [80, 8080, 8000, 9000, 6379, -1]) {
            if (port == -1) {
                throw "Test HTTP server not found";
            }

            try {
                socket.connect(new Host("localhost"), port);
            } catch (exception:String) {
                continue;
            }

            break;
        }
    }
}
