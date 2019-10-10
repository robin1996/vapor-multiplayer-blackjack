//
//  Player.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 10/10/2019.
//

import Vapor

protocol Player {
    var model: PlayerModel { get set }
    func request(actions: [PlayerAction], withType type: PlayerRequest.RequestType, onLoop eventLoop: EventLoop) throws -> Future<PlayerResponse?>
}
