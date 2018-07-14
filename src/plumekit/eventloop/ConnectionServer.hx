package plumekit.eventloop;

import callnest.Task;
import callnest.VoidReturn;
import commonbox.ds.Set;
import haxe.CallStack;
import plumekit.Exception.SystemException;
import plumekit.net.Connection;
import plumekit.net.ConnectionAddress;

using callnest.TaskTools;


private enum ServerState {
    Ready;
    Running;
    Stopping;
    Stopped;
}


class ConnectionServer {
    var eventLoop:EventLoop;
    var handlerCallback:Connection->Task<VoidReturn>;
    var state = Ready;
    var serverConnection:Connection;
    var currentAcceptTask:Task<Connection>;
    var concurrentLimit:Int;
    var handlerTasks:Set<Task<VoidReturn>>;

    public function new(handlerCallback:Connection->Task<VoidReturn>,
            concurrentLimit:Int = 1000, ?eventLoop:EventLoop) {
        if (eventLoop == null) {
            eventLoop = DefaultEventLoop.instance();
        }

        this.handlerCallback = handlerCallback;
        this.concurrentLimit = concurrentLimit;
        this.eventLoop = eventLoop;
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
        serverConnection = eventLoop.newConnection();

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
            // Reached max limit, wait for this one to finish instead
            // of trying more accepts
            return handlerTask.continueNext(acceptIteration);
        } else {
            return acceptIteration();
        }
    }

    function handlerCompleteCallback(connection:Connection, task:Task<VoidReturn>) {
        connection.close();
        handlerTasks.remove(task);

        try {
            task.getResult();
        } catch (exception:Any) {
            handleException(exception);
        }
    }

    function handleException(exception:Any) {
        trace('Server handler exception: $exception');
        trace(CallStack.toString(CallStack.exceptionStack()));
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
