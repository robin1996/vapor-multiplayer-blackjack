//
//  Helpers.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 08/10/2019.
//

import Foundation

enum DummyData {
    
    static var hand: Hand {
        return Hand(id: 42, cards: [card], totalType: .hard, total: 1234, stake: 4321, winnings: 2323)
    }
    
    static var card: Card {
        return Card(suit: .diamonds, rank: .four)
    }
    
}
