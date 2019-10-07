//
//  GameSocketController.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 07/10/2019.
//

import Vapor

fileprivate struct WeakWebSocket {
    weak var object: WebSocket?
}

class GameController {

    private var _clients = [ObjectIdentifier: WeakWebSocket]()
    var clients: [WebSocket] {
        var array = [WebSocket]()
        for (id, socket) in _clients {
            guard let client = socket.object else {
                _clients.removeValue(forKey: id)
                continue
            }
            array.append(client)
        }
        return array
    }

    func sendGlobal(message: String) {
        print("Message sent: \(message)")
        clients.forEach { (webSocket) in
            webSocket.send(message)
        }
    }

    func setup(webSocket: WebSocket) {
        let id = ObjectIdentifier(webSocket)
        _clients[id] = WeakWebSocket(object: webSocket)
        webSocket.onCloseCode { [weak self] (_) in
            self?.remove(webSocket: webSocket)
        }
        webSocket.onText { [weak self] (_, text) in
            self?.sendGlobal(message: text)
        }
        webSocket.onError { [weak self] (webSocket, _) in
            self?.remove(webSocket: webSocket)
        }
        print("New client joined!")
        sendGlobal(message: "New client joined!")
    }

    func remove(webSocket: WebSocket) {
        _clients.removeValue(forKey: ObjectIdentifier(webSocket))
        print("Client disconnected.")
        sendGlobal(message: "Client diconnected.")
    }

}
