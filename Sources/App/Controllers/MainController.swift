//
//  SocketController.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 11/10/2019.
//

import Vapor

class MainController {

    let casterPool = CasterPoolController()
    let clientPool = ClientPoolController()
    let gameController = GameController()

    init() {
        gameController.delegate = self
        gameController.broadcaster = casterPool
        casterPool.delegate = self
        clientPool.delegate = self
    }

}

extension MainController: Provider {

    func register(_ services: inout Services) throws {
        try services.register(DatabaseController())
    }

    func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        gameController.database = try container.make(DatabaseController.self)
        gameController.database?.app = container
        return .done(on: container)
    }

}

extension MainController: GameControllerDelegate {

    private func nameList(of clients: Clients) -> String {
        return clients.reduce("") { (string, client) -> String in
            "\(string) \(["🤩", "🤯", "🥳", "😎"][Int.random(in: 0...3)]) \(client.model.username) "
        }
    }

    func gameStarted(with clients: Clients, gameController: GameController) {
        clientPool.sendGlobal(message: "Game started with \(nameList(of: clients))")
    }

    func gameEnded(with clients: Clients, gameController: GameController) {
        clientPool.sendGlobal(message: "Game ended with \(nameList(of: clients))")
        guard !clientPool.clients.isEmpty else { return }
        gameController.start(withClients: clientPool.clients)
    }

}

extension MainController: ClientPoolDelegate {

    func clientDisconnected(_ client: ClientController?) {
        if gameController.clients.contains(where: { (c) -> Bool in
            c === client
        }) {
            gameController.end()
        }
    }

    func clientConnected(_ client: ClientController) {
        gameController.end()
        gameController.start(withClients: clientPool.clients)
    }

}

extension MainController: CasterPoolDelegate {

    func casterConnected(_ socket: WebSocket) {
        let data = try! BlackjackEncoder().encode(gameController.getGameState())
        socket.send(data)
    }

}

// MARK: - Real time commands
extension MainController {

    func getState() -> String {
        var result = "No game 🥺"
        if let data = try? BlackjackEncoder().encode(gameController.getGameState()),
            let string = String(data: data, encoding: .utf8) {
            result = string
        }
        return result
    }

    func getClients() -> String {
        return clientPool.clients.reduce("", { (text, client) -> String in
            let newText = "\(text)\(client.model.username)\t"
            if let socket = client.socket {
                return "\(newText)\(ObjectIdentifier(socket))\n"
            } else {
                return "\(newText)\n"
            }
        })
    }

    func getCasters() -> String {
        return casterPool.casters.reduce("", { (text, caster) -> String in
            return "\(text)\(ObjectIdentifier(caster))\n"
        })
    }

    func killGame() -> String {
        gameController.end()
        return "Done 👍"
    }

}
