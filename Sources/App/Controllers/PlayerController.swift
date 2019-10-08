//
//  GameSocketController.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 07/10/2019.
//

import Vapor

enum PlayerRequestError: Error {
    case missingSocket
}

enum PlayerResponseError: Error {
    
}

class Client {
    weak var socket: WebSocket?
    var player: Player
    
    init(socket: WebSocket, username: String) {
        self.socket = socket
        self.player = Player(username: username)
        
        #warning("Dummy")
        player.hands = [DummyData.hand]
    }
    
    func request(actions: [PlayerAction], type: PlayerRequest.RequestType) throws {
        let request = PlayerRequest(actions: actions, type: type, player: player)
        let data = try JSONEncoder().encode(request)
        guard let socket = socket else {
            throw PlayerRequestError.missingSocket
        }
        socket.send(data)
    }
}

class PlayerController {

    private var _clients = [ObjectIdentifier: Client]()
    var clients: [Client] {
        var array = [Client]()
        for (id, client) in _clients {
            guard client.socket != nil else {
                _clients.removeValue(forKey: id)
                continue
            }
            array.append(client)
        }
        return array
    }
    var responseHandler: ((WebSocket, Data) -> Void)?
    
    init() {
        responseHandler = { (socket, data) in
            let response = try? JSONDecoder().decode(PlayerResponse.self, from: data)
            let client = self._clients[ObjectIdentifier(socket)]
            // Handle response here
            
            #warning("Dummy")
            print("🎉 Response from \(client?.player.username) 🎉")
            print(response)
            client?.player.hands[0].cards.append(DummyData.card)
            try? client?.request(actions: [.hit], type: .inProgress)
        }
    }

    func sendGlobal(message: String) {
        print("Message sent: \(message)")
        clients.forEach { (client) in
            client.socket?.send(message)
        }
    }

    func setup(webSocket: WebSocket, withName username: String) {
        let client = Client(socket: webSocket, username: username)
        let id = ObjectIdentifier(webSocket)
        _clients[id] = client
//        webSocket.onCloseCode { [weak self] (_) in
//            self?.remove(webSocket: webSocket)
//        }
        webSocket.onText { [weak self] (_, text) in
            self?.sendGlobal(message: text)
        }
//        webSocket.onError { [weak self] (webSocket, _) in
//            self?.remove(webSocket: webSocket)
//        }
        webSocket.onBinary(responseHandler!)
        print("New client joined!")
        sendGlobal(message: "New client joined!")
        try? client.request(actions: [], type: .waiting)
    }
    
    

//    func remove(webSocket: WebSocket) {
//        _clients.removeValue(forKey: ObjectIdentifier(webSocket))
//        print("Client disconnected.")
//        sendGlobal(message: "Client diconnected.")
//    }

}
