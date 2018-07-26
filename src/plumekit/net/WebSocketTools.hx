package plumekit.net;

import js.html.WebSocket;


class WebSocketTools {
    public static function isClosed(webSocket:WebSocket):Bool {
        return webSocket.readyState == WebSocket.CLOSING
            || webSocket.readyState == WebSocket.CLOSED;
    }
}
