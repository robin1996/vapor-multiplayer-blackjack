//
//  DatabaseController.swift
//  App
//
//  Created by Robin Douglas on 15/10/2019.
//

import Vapor

class DatabaseController: Service {

    weak var container: Container?

    func playerModelFor(username: String) -> Future<PlayerModel>? {
        guard let container = container else { return nil }
        let promise = container.eventLoop.newPromise(PlayerModel.self)
        SQLitePlayer.find(username, on: Request(using: container)).addAwaiter { (result) in
            if let maybePlayer = result.result,
                let player = maybePlayer,
                let playerModel = PlayerModel(sqliteModel: player) {
                promise.succeed(result: playerModel)
            } else {
                promise.succeed(result: PlayerModel(username: username))
            }
        }
        return promise.futureResult
    }

    static func getPlayers(on request: Request) -> Future<[SQLitePlayer]> {
        return SQLitePlayer.query(on: request).all()
    }

    func savePlayer(_ player: PlayerModel) -> Future<Void>? {
        guard let container = container else { return nil }
        let name = player.username
        print("💽 Saving \(name)")
        let sqlitePlayer = player.sqliteModel()
        return container.withPooledConnection(to: .sqlite) { (connection) -> Future<Void> in
            let promise = connection.eventLoop.newPromise(of: Void.self)
            let callback: (FutureResult<SQLitePlayer>) -> Void = { (result) in
                if let error = result.error {
                    print("⚠️ Error saving \(name): \(error.localizedDescription)")
                    promise.fail(error: error)
                } else if let name = result.result?.username {
                    print("💰 Winnings saved for \(name)")
                    promise.succeed()
                } else {
                    print("☣️ UNKNOWN DATABASE ERROR ☣️")
                    promise.fail(error: DatabaseError.NoDatabase)
                }
            }
            // Need to do the following because .save doesn't work.
            SQLitePlayer.find(name, on: connection).addAwaiter(callback: { (result) in
                if let test = result.result, test != nil {
                    sqlitePlayer.update(on: connection).addAwaiter(callback: callback)
                } else {
                    sqlitePlayer.create(on: connection).addAwaiter(callback: callback)
                }
            })
            return promise.futureResult
        }
    }

}
