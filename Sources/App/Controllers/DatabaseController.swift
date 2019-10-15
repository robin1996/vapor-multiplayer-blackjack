//
//  DatabaseController.swift
//  App
//
//  Created by Robin Douglas on 15/10/2019.
//

import Vapor

class DatabaseController: Service {

    weak var app: Container? {
        didSet {
            getPlayers()?.addAwaiter(callback: { [weak self] (result) in
                guard let players = result.result else { return }
                self?.players = players
            })
        }
    }
    private var players: [SQLitePlayer] = []

    func getPlayers() -> Future<[SQLitePlayer]>? {
        guard let app = app else { return nil }
        return SQLitePlayer.query(on: Request(using: app)).all()
    }

    func updateWinningsFor(player: Player) {
        guard let hand = player.hand else { return }
        guard let app = app else { return }
        let ammount = player.model.status == .win ? hand.stake : -hand.stake
        let name = player.model.username
        if let sqplayer = players.reduce(nil, { (_, sqplayer) -> SQLitePlayer? in
            return sqplayer.username == name ? sqplayer : nil
        }) {
            sqplayer.winnings += ammount
            _ = sqplayer.update(on: Request(using: app))
        } else {
            let sqplayer = SQLitePlayer(username: name, winnings: ammount)
            _ = sqplayer.create(on: Request(using: app))
            players.append(sqplayer)
        }
    }

}
