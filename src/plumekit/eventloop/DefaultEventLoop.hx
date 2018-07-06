package plumekit.eventloop;


class DefaultEventLoop {
    static var _instance:EventLoop;

    public dynamic static function newEventLoop():EventLoop {
        return new SelectEventLoop();
    }

    public static function instance():EventLoop {
        if (_instance == null) {
            _instance = newEventLoop();
        }

        return _instance;
    }
}
