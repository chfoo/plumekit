package plumekit.test.net.cases;

import plumekit.net.NetException;
import utest.Assert;
import plumekit.eventloop.EventLoop;

using plumekit.TaskTestTools;


class ConnectAcceptTestCase {
    static inline var SOCKET_TIMEOUT = 5.0;

    public function new() {
    }

    function newEventLoop():EventLoop {
        throw "Not implemented";
    }

    public function testConnectAndAccept() {
        var eventLoop = newEventLoop();
        var serverConnection = eventLoop.newConnection();
        var clientConnection = eventLoop.newConnection();

         var gotAccept = false;

        var done = TaskTestTools.startAsync(function () {
            Assert.isTrue(gotAccept);
        });

        serverConnection.connectTimeout = SOCKET_TIMEOUT;
        serverConnection.bind("localhost", 0);
        serverConnection.listen(1);
        serverConnection.accept()
            .onComplete(function (task) {
                var childConnection = task.getResult();

                Assert.notNull(childConnection);
                gotAccept = true;
                childConnection.close();
            })
            .handleException(TaskTestTools.exceptionHandler);

        var port = serverConnection.hostAddress().port;

        clientConnection.connectTimeout = SOCKET_TIMEOUT;
        clientConnection.connect("localhost", port)
            .onComplete(function (task) {
                var connectedConnection = task.getResult();

                Assert.notNull(connectedConnection);

                eventLoop.stop();
                done();
            })
            .handleException(TaskTestTools.exceptionHandler);

        eventLoop.startTimedTest();
    }

    public function testConnectFailure() {
        var eventLoop = newEventLoop();
        var connection = eventLoop.newConnection();

        var done = TaskTestTools.startAsync();

        connection.connectTimeout = SOCKET_TIMEOUT;
        connection.connect("localhost", 4).onComplete(function (task) {
            Assert.raises(task.getResult, NetException);
            done();
        });

        eventLoop.startTimedTest();
    }
}
