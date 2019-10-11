//
//  CasterPoolController.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 11/10/2019.
//

import Vapor

typealias Casters = [WebSocket]

struct Caster {
    weak var socket: WebSocket?
}

class CasterPoolController {

    private var _casters = [ObjectIdentifier: Caster]()
    var casters: Casters {
        var array = Casters()
        for (id, caster) in _casters {
            guard let socket = caster.socket else {
                _casters.removeValue(forKey: id)
                continue
            }
            array.append(socket)
        }
        return array
    }
    weak var delegate: CasterPoolDelegate?

    func setup(webSocket: WebSocket) {
        _casters[ObjectIdentifier(webSocket)] = Caster(socket: webSocket)
        delegate?.casterConnected(webSocket)
    }

}

extension CasterPoolController: Broadcaster {

    func cast(state: GameState) {
        let data = try! BlackjackEncoder().encode(state)
        casters.forEach { (socket) in
            socket.send(data)
        }
    }

}
