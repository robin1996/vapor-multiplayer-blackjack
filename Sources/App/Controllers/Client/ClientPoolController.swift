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
    weak var database: DatabaseController?

    func sendGlobal(message: String) {
        print("☎️ Message sent: \(message)")
        clients.forEach { (client) in
            client.socket?.send(message)
        }
    }

    func setup(webSocket: WebSocket, withName username: String) {
        guard !usernameInUser(username) else {
            print("⚠️ Name \(username) is already in use")
            webSocket.close(code: .policyViolation)
            return
        }
        database?.playerModelFor(username: username)?.addAwaiter(callback: {
            [weak self, weak webSocket] (result) in
            guard let model = result.result,
                let self = self,
                let webSocket = webSocket else {
                    print("☣️ FAILED TO SETUP CLIENT ☣️")
                    return
            }
            let client = ClientController(socket: webSocket, model: model)
            let id = ObjectIdentifier(webSocket)
            self._clients[id] = client
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
            self.sendGlobal(message: "New client joined!")
            self.delegate?.clientConnected(client)
        })

    }

    func remove(webSocket: WebSocket) {
        let id = ObjectIdentifier(webSocket)
        let client = _clients[id]
        _clients.removeValue(forKey: id)
        sendGlobal(message: "\(client?.model.username ?? "Client") diconnected")
        delegate?.clientDisconnected(client)
    }

    private func usernameInUser(_ username: String) -> Bool {
        return clients.reduce(false) { (result, client) -> Bool in
            return result || username == client.model.username
        }
    }

}
