//
//  RequestTypeMatching.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 10/10/2019.
//

import Foundation

func ~=(pattern: PlayerAction, value: [PlayerAction]) -> Bool {
    return value.contains(pattern)
}
