package plumekit.net;

import callnest.Task;
import callnest.TaskTools;
import plumekit.Exception.SystemException;


class ConnectionServer {
    var connectionFactory:Void->Connection;
    var handlerCallback:Connection->Void;
    var running = false;
    var serverConnection:Connection;
    var currentAcceptTask:Task<Connection>;

    public function new(connectionFactory:Void->Connection,
            handlerCallback:Connection->Void) {
        this.connectionFactory = connectionFactory;
        this.handlerCallback = handlerCallback;
    }

    public function hostAddress():ConnectionAddress {
        return serverConnection.hostAddress();
    }

    public function start(hostname:String, port:Int):Task<ConnectionServer> {
        if (running) {
            throw new SystemException("Server already started");
        }

        running = true;
        serverConnection = connectionFactory();

        serverConnection.bind(hostname, port);
        serverConnection.listen(8);

        Debug.assert(currentAcceptTask == null);
        currentAcceptTask = serverConnection.accept();
        return currentAcceptTask.continueWith(acceptIteration);
    }

    function acceptIteration(task:Task<Connection>):Task<ConnectionServer> {
        Debug.assert(currentAcceptTask != null);
        currentAcceptTask = null;

        if (task.isCanceled || !running) {
            return TaskTools.fromResult(this);
        }

        var clientConnection = task.getResult();
        handlerCallback(clientConnection);

        Debug.assert(currentAcceptTask == null);
        currentAcceptTask = serverConnection.accept();
        return currentAcceptTask.continueWith(acceptIteration);
    }

    public function stop() {
        if (running) {
            trace("server quit");
            serverConnection.close();

            if (currentAcceptTask != null) {
                currentAcceptTask.cancel();
            }
        }

        running = false;
    }
}
