//
//  GameSocketController.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 07/10/2019.
//

import Vapor

typealias Clients = [ClientController]

class ClientPoolController {

    private var _clients = [ObjectIdentifier: ClientController]()
    var clients: Clients {
        var array = Clients()
        for (id, client) in _clients {
            guard client.socket != nil else {
                _clients.removeValue(forKey: id)
                continue
            }
            array.append(client)
        }
        return array
    }
    weak var delegate: ClientPoolDelegate?

    func sendGlobal(message: String) {
        print("☎️ Message sent: \(message)")
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
        webSocket.onCloseCode { [weak self] (_) in
            self?.remove(webSocket: webSocket)
        }
        webSocket.onClose.always { [weak self, weak webSocket] in
            guard let socket = webSocket else { return }
            self?.remove(webSocket: socket)
        }
        webSocket.onError { [weak self] (webSocket, _) in
            self?.remove(webSocket: webSocket)
        }
        sendGlobal(message: "New client joined!")
        delegate?.clientConnected(client)
    }

    func remove(webSocket: WebSocket) {
        let id = ObjectIdentifier(webSocket)
        let client = _clients[id]
        _clients.removeValue(forKey: id)
        sendGlobal(message: "Client diconnected")
        delegate?.clientDisconnected(client)
    }

}
