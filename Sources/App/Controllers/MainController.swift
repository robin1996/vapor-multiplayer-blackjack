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
    private let gameController = GameController()

    init() {
        gameController.delegate = self
        gameController.broadcaster = casterPool
        clientPool.delegate = self
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
    }

}

extension MainController: ClientPoolDelegate {

    func clientDisconnected(_ client: ClientController?) {
        if gameController.clients.contains(where: { (c) -> Bool in
            c === client
        }) {
            gameController.end()
        }
        clientPool.sendGlobal(
            message: "\(client?.model.username ?? "Client") disconnected"
        )
    }

    func clientConnected(_ client: ClientController) {
        gameController.end()
        gameController.start(withClients: clientPool.clients)
    }

}
