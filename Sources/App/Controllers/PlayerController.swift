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
    let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()

    init(socket: WebSocket, username: String) {
        self.socket = socket
        self.player = Player(username: username)

        #warning("Dummy")
        player.hands = [DummyData.hand]
    }

    func request(actions: [PlayerAction], type: PlayerRequest.RequestType) throws -> Future<PlayerResponse?> {
        let request = PlayerRequest(actions: actions, type: type, player: player)
        let data = try JSONEncoder().encode(request)
        guard let socket = socket else {
            throw PlayerRequestError.missingSocket
        }
        socket.send(data)
        let promise = eventLoop.newPromise(of: PlayerResponse?.self)
        if request.actions.isEmpty {
            promise.succeed(result: nil)
        } else {
            socket.onBinary { (_, data) in
                guard let response = try? JSONDecoder().decode(PlayerResponse.self, from: data) else {
                    fatalError("Decoding error")
                }
                promise.succeed(result: response)
            }
        }
        return promise.futureResult
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
    var game: GameController?
//    var responseHandler: ((WebSocket, Data) -> Void)?
//
//    init() {
//        responseHandler = { (socket, data) in
//            let response = try? JSONDecoder().decode(PlayerResponse.self, from: data)
//            let client = self._clients[ObjectIdentifier(socket)]
//            // Handle response here
//
//            #warning("Dummy")
//            print("🎉 Response from \(client?.player.username) 🎉")
//            print(response)
//            client?.player.hands[0].cards.append(DummyData.card)
//            try? client?.request(actions: [.hit], type: .inProgress)
//        }
//    }

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
//        webSocket.onBinary(responseHandler!)
        print("New client joined!")
        sendGlobal(message: "New client joined!")
//        try? client.request(actions: [], type: .waiting)
        game = GameController(clients: clients)
        game?.start()
    }

//    func remove(webSocket: WebSocket) {
//        _clients.removeValue(forKey: ObjectIdentifier(webSocket))
//        print("Client disconnected.")
//        sendGlobal(message: "Client diconnected.")
//    }

}

class GameController {

    var deck: Deck = []
    var clients: [Client]
    var turn = 0
    var client: Client {
        return clients[Int(Double(turn).truncatingRemainder(dividingBy: Double(clients.count)))]
    }

    init(clients: [Client]) {
        self.clients = clients
    }

    func start() {
        deck = Deck.standard()
        takeTurn()
    }

    private func takeTurn() {
        let client = self.client
        print("🤞 Requesting action from \(client.player.username)")
        (try! client.request(actions: [.hit], type: .inProgress)).addAwaiter { (result) in
            if let unwrap = result.result, let result = unwrap {
                print("🤩 Got a response!!!")
                switch result.action {
                case .double: break
                case .hit:
                    client.player.hands[0].cards.append(self.deck.drawCard())
                case .split: break
                case .stake: break
                case .stand: break
                }
            } else {
                print("🤔 no response, were they asked for an action?")
            }
            self.turn += 1
            self.takeTurn()
        }

    }

}
