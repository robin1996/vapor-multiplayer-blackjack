//
//  GameSocketController.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 07/10/2019.
//

import Vapor

class ClientPoolController {

    private var _clients = [ObjectIdentifier: ClientController]()
    var clients: [ClientController] {
        var array = [ClientController]()
        for (id, client) in _clients {
            guard client.socket != nil else {
                _clients.removeValue(forKey: id)
                continue
            }
            array.append(client)
        }
        return array
    }
    var game: GameController?

    func sendGlobal(message: String) {
        print("Message sent: \(message)")
        clients.forEach { (client) in
            client.socket?.send(message)
        }
    }

    func setup(webSocket: WebSocket, withName username: String) {
        let client = ClientController(socket: webSocket, username: username)
        let id = ObjectIdentifier(webSocket)
        _clients[id] = client
        webSocket.onText { [weak self] (_, text) in
            self?.sendGlobal(message: text)
        }
//        webSocket.onCloseCode { [weak self] (_) in
//            self?.remove(webSocket: webSocket)
//        }
//        webSocket.onError { [weak self] (webSocket, _) in
//            self?.remove(webSocket: webSocket)
//        }
        print("New client joined!")
        sendGlobal(message: "New client joined!")
        game?.end()
        game = GameController(clients: clients)
        game?.start()
    }

//    func remove(webSocket: WebSocket) {
//        _clients.removeValue(forKey: ObjectIdentifier(webSocket))
//        print("Client disconnected.")
//        sendGlobal(message: "Client diconnected.")
//    }

}
