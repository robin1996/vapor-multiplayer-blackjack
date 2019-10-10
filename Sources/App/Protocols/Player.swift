//
//  Player.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 10/10/2019.
//

import Vapor

protocol Player: AnyObject {
    var model: PlayerModel { get set }
    var hand: Hand? { get }
    func request(actions: [PlayerAction], withType type: PlayerRequest.RequestType, onLoop eventLoop: EventLoop) throws -> Future<PlayerResponse?>
}

extension Player {
    var hand: Hand? {
        guard !model.hands.isEmpty else { return nil }
        return model.hands[0]
    }
}
