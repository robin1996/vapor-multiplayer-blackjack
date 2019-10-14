//
//  Dealer.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 10/10/2019.
//

import Vapor

class Dealer: Player {

    var model: PlayerModel

    init() {
        model = PlayerModel(username: "Dealer guy")
    }

    func request(
        actions: [PlayerAction],
        onLoop eventLoop: EventLoop
    ) throws -> EventLoopFuture<PlayerResponse?> {
        let promise = eventLoop.newPromise(of: PlayerResponse?.self)
        switch (actions, hand?.bestTotal() ?? -1) {
        case (.stake, _):
            promise.succeed(result: PlayerResponse(action: .stake, value: -1))
        case (.hit, ...17):
            eventLoop.scheduleTask(in: TimeAmount.seconds(1)) {
                promise.succeed(result: PlayerResponse(action: .hit, value: nil))
            }
        case (.stand, _):
            promise.succeed(result: PlayerResponse(action: .stand, value: 0))
        default:
            promise.succeed(result: nil)
        }
        return promise.futureResult
    }

}
