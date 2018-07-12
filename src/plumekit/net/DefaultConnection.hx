package plumekit.net;


class DefaultConnection {
    public dynamic static function newConnection():Connection {
        return new SelectConnection();
    }
}
