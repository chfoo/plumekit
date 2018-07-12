package plumekit.net;

import commonbox.ds.Set;
import callnest.Task;
import callnest.TaskTools;
import plumekit.Exception.SystemException;


private enum ServerState {
    Ready;
    Running;
    Stopping;
    Stopped;
}


class ConnectionServer {
    var connectionFactory:Void->Connection;
    var handlerCallback:Connection->Task<Connection>;
    var state = Ready;
    var serverConnection:Connection;
    var currentAcceptTask:Task<Connection>;
    var concurrentLimit:Int;
    var handlerTasks:Set<Task<Connection>>;

    public function new(handlerCallback:Connection->Task<Connection>,
            concurrentLimit:Int = 1000,
            ?connectionFactory:Void->Connection) {
        if (connectionFactory == null) {
            connectionFactory = DefaultConnection.newConnection;
        }

        this.handlerCallback = handlerCallback;
        this.concurrentLimit = concurrentLimit;
        this.connectionFactory = connectionFactory;
        handlerTasks = new Set();
    }

    public function hostAddress():ConnectionAddress {
        return serverConnection.hostAddress();
    }

    public function start(hostname:String, port:Int):Task<ConnectionServer> {
        if (state != Ready) {
            throw new SystemException("Server already started");
        }

        state = Running;
        serverConnection = connectionFactory();

        serverConnection.bind(hostname, port);
        serverConnection.listen(8);

        return acceptIteration();
    }

    function acceptIteration():Task<ConnectionServer> {
        if (state == Stopping) {
            return waitForHandlersComplete();
        } else if (state == Stopped) {
            return TaskTools.fromResult(this);
        }

        Debug.assert(currentAcceptTask == null);
        currentAcceptTask = serverConnection.accept();
        return currentAcceptTask.continueWith(acceptCallback);
    }

    function acceptCallback(task:Task<Connection>):Task<ConnectionServer> {
        currentAcceptTask = null;

        if (task.isCanceled) {
            return acceptIteration();
        }

        var connection = task.getResult();

        var handlerTask = handlerCallback(connection);
        handlerTasks.add(handlerTask);
        handlerTask.onComplete(handlerCompleteCallback.bind(connection));

        if (handlerTasks.length >= concurrentLimit) {
            return handlerTask.continueWith(function (task) {
                task.getResult();
                return acceptIteration();
            });
        } else {
            return acceptIteration();
        }
    }

    function handlerCompleteCallback(connection:Connection, task:Task<Connection>) {
        connection.close();
        handlerTasks.remove(task);
        task.getResult();
    }

    function waitForHandlersComplete():Task<ConnectionServer> {
        return TaskTools.whenAll(handlerTasks).continueWith(function (task) {
            task.getResult();
            Debug.assert(handlerTasks.length == 0, handlerTasks.length);
            shutdown();
            return TaskTools.fromResult(this);
        });
    }

    public function stop(immediate:Bool = false) {
        if ((state == Running || state == Stopping) && immediate) {
            cancelAccept();
            shutdown();
        } else if (state == Running) {
            state = Stopping;
            cancelAccept();
        }
    }

    function cancelAccept() {
        if (currentAcceptTask != null && !currentAcceptTask.isComplete) {
            currentAcceptTask.cancel();
        }
    }

    function shutdown() {
        serverConnection.close();
        state = Stopped;
    }
}
