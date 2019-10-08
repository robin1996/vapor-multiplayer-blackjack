//
//  Helpers.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 08/10/2019.
//

import Foundation

enum DummyData {
    
    static var hand: Hand {
        return Hand(
            id: 42,
            cards: [card],
            totalType: .hard,
            total: "initial total",
            stake: 5451,
            winnings: 412
        )
    }
    
    static var card: Card {
        return Card(suit: .diamonds, rank: .four)
    }
    
}
