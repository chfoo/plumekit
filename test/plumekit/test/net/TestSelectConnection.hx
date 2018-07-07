package plumekit.test.net;

import plumekit.eventloop.SelectEventLoop;
import plumekit.net.NetException;
import plumekit.net.SelectConnection;
import plumekit.net.SelectDispatcher;
import utest.Assert;

using plumekit.eventloop.EventLoopTools;


class TestSelectConnection {
    static inline var TEST_TIMEOUT = 10000;
    static inline var LOOP_DURATION = 5.0;
    static inline var SOCKET_TIMEOUT = 5.0;

    public function new() {
    }

    public function testConnectAndAccept() {
        var dispatcher = new SelectDispatcher();
        var eventLoop = new SelectEventLoop(dispatcher);
        var serverConnection = new SelectConnection(dispatcher);
        var clientConnection = new SelectConnection(dispatcher);

        var gotAccept = false;

        var done = Assert.createAsync(function () {
            Assert.isTrue(gotAccept);
        }, TEST_TIMEOUT);

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
            .handleException(exceptionHandler);

        var port = serverConnection.hostAddress().port;

        clientConnection.connectTimeout = SOCKET_TIMEOUT;
        clientConnection.connect("localhost", port)
            .onComplete(function (task) {
                var connectedConnection = task.getResult();

                Assert.notNull(connectedConnection);

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

    function testConnectFailure() {
        var dispatcher = new SelectDispatcher();
        var eventLoop = new SelectEventLoop(dispatcher);
        var connection = new SelectConnection(dispatcher);

        var done = Assert.createAsync(TEST_TIMEOUT);

        connection.connectTimeout = SOCKET_TIMEOUT;
        connection.connect("localhost", 4).onComplete(function (task) {
            Assert.raises(task.getResult, NetException);
            done();
        });

        eventLoop.startTimed(LOOP_DURATION);
    }
}
