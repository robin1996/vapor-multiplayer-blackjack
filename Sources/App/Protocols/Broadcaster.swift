//
//  Broadcaster.swift
//  App
//
//  Created by Robin Douglas on 11/10/2019.
//

import Foundation

protocol Broadcaster: AnyObject {
    func cast(state: GameState)
}
