package plumekit.test.www.gopher;

#if sys
import callnest.Task;
import callnest.TaskTools;
import haxe.ds.Option;
import plumekit.eventloop.DefaultEventLoop;
import plumekit.www.gopher.Client;
import plumekit.www.gopher.DirectoryEntity;
import plumekit.www.gopher.Server;
import utest.Assert;

using plumekit.TaskTestTools;
#end

class TestServerClient {
    public function new() {
    }

#if sys
    public function test() {
        var eventLoop = DefaultEventLoop.newEventLoop();
        var server = new Server(eventLoop);
        var client = new Client(eventLoop);

        var serverTask = server.start("localhost", 0);
        var menu;
        var directoryEntities = [];
        var done = TaskTestTools.startAsync(function () {
            Assert.equals(1, directoryEntities.length);
        });

        var menuCallback;

        function menuIteration():Task<Array<DirectoryEntity>> {
            return menu.next().continueWith(menuCallback);
        }

        menuCallback = function (task:Task<Option<DirectoryEntity>>) {
             switch (task.getResult()) {
                case Some(directoryEntity):
                    directoryEntities.push(directoryEntity);
                    return menuIteration();
                case None:
                    return TaskTools.fromResult(directoryEntities);
            }
        }

        client.requestMenu("localhost", server.hostAddress().port, "")
            .continueWith(function (task) {
                menu = task.getResult();
                trace(menu);
                return menuIteration();
            })
            .continueWith(function (task) {
                task.getResult();
                server.stop();
                trace("stopping");
                return serverTask;
            })
            .onComplete(function (task) {
                task.getResult();
                eventLoop.stop();
                done();
            })
            .handleException(TaskTestTools.exceptionHandler);

        eventLoop.startTimedTest();
    }
#end
}
