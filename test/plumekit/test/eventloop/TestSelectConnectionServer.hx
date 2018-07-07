package plumekit.test.eventloop;

import callnest.Task;
import callnest.TaskTools;
import haxe.io.Bytes;
import plumekit.eventloop.SelectEventLoop;
import plumekit.net.Connection;
import plumekit.net.ConnectionServer;
import plumekit.net.SelectConnection;
import plumekit.net.SelectDispatcher;
import plumekit.stream.BufferedReader;
import plumekit.stream.ReadResult;
import plumekit.stream.StreamReader;
import plumekit.stream.StreamWriter;
import utest.Assert;

using plumekit.eventloop.EventLoopTools;


class TestSelectConnectionServer {
    static inline var TEST_TIMEOUT = 10000;
    static inline var LOOP_DURATION = 5.0;
    static inline var SOCKET_TIMEOUT = 5.0;

    var dispatcher:SelectDispatcher;
    var eventLoop:SelectEventLoop;
    var server:ConnectionServer;
    var serverTask:Task<ConnectionServer>;

    public function new() {
        dispatcher = new SelectDispatcher();
        eventLoop = new SelectEventLoop(dispatcher);

        var connectionFactory = SelectConnection.new.bind(null, dispatcher);
        server = new ConnectionServer(connectionFactory, serverHandlerCallback);
    }

    function startServer() {
        serverTask = server.start("localhost", 0);
        trace('Server on port ${server.hostAddress().port}');
    }

    function stopServer() {
        server.stop();
        serverTask.getResult();
    }

    public function test() {
        var clientTasks = [];

        startServer();

        for (index in 0...10) {
            clientTasks.push(clientConnect());
        }

        var done = Assert.createAsync(function() {
            for (clientTask in clientTasks) {
                try {
                    var text = clientTask.getResult().toString();
                    Assert.equals("Hello world!\n", text);
                } catch (exception:Any) {
                    Assert.fail(exception);
                }
            }
        }, TEST_TIMEOUT);

        TaskTools.whenAll(clientTasks).onComplete(function (tasks) {
            trace('stopping');
            stopServer();
            eventLoop.stop();

            done();
        });

        eventLoop.startTimed(LOOP_DURATION);
    }

    function serverHandlerCallback(connection:Connection) {
        var reader = new BufferedReader(connection.source);
        var writer = new StreamWriter(connection.sink);
        trace("server handler callback");

        reader.readUntil("\n".code)
            .continueWith(function (task) {
                switch (task.getResult()) {
                    case ReadResult.Success(bytes):
                        trace("server echoing");
                        return writer.write(bytes);
                    case ReadResult.Incomplete(bytes):
                        return TaskTools.fromResult(0);
                }
            })
            .onComplete(function (task) {
                trace("server handler closing");
                connection.close();
                task.getResult();
            })
            .handleException(exceptionHandler);
    }

    function clientConnect() {
        var clientConnection = new SelectConnection(dispatcher);
        var clientReader = new StreamReader(clientConnection.source);
        var clientWriter = new StreamWriter(clientConnection.sink);

        clientConnection.connectTimeout = SOCKET_TIMEOUT;
        clientConnection.sink.writeTimeout = SOCKET_TIMEOUT;
        clientConnection.source.readTimeout = SOCKET_TIMEOUT;

        return clientConnection
            .connect("localhost", server.hostAddress().port)
            .continueWith(function (task) {
                task.getResult();
                trace("client sending hello");
                return clientWriter.write(Bytes.ofString("Hello world!\n"));
            })
            .continueWith(function (task) {
                task.getResult();
                trace("client receiving hello");
                return clientReader.readAll();
            })
            .continueWith(function (task) {
                clientConnection.close();
                trace("client done");
                return task;
            });
    }

    function exceptionHandler(exception:Any) {
        Assert.fail(exception);
        throw exception;
    }
}
