//
//  ClientController.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 08/10/2019.
//

import Vapor

enum PlayerRequestError: Error {
    case missingSocket
}

class ClientController: Player {

    weak var socket: WebSocket?
    var model: PlayerModel

    init(socket: WebSocket, model: PlayerModel) {
        self.socket = socket
        self.model = model
    }

    func request(
        actions: [PlayerAction],
        onLoop eventLoop: EventLoop
    ) throws -> Future<PlayerResponse?> {
        // Create request
        let request = PlayerRequest(actions: actions, player: model)
        let data = try BlackjackEncoder().encode(request)
        guard let socket = socket else {
            throw PlayerRequestError.missingSocket
        }
        socket.send(data)
        let promise = eventLoop.newPromise(of: PlayerResponse?.self)
        if request.actions.isEmpty {
            promise.succeed(result: nil)
        } else {
            socket.onBinary { (_, data) in
                do {
                    let response = try BlackjackDecoder().decode(
                        PlayerResponse.self,
                        from: data
                    )
                    promise.succeed(result: response)
                } catch {
                    promise.fail(error: error)
                }
            }
        }
        return promise.futureResult
    }

}
