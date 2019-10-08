//
//  Deck.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 07/10/2019.
//

import Foundation

typealias Deck = [Card]

extension Deck {

    static func standard() -> Deck {
        var deck = Deck()
        for s in Suit.allCases {
            for r in Rank.allCases {
                deck.append(Card(suit: s, rank: r))
            }
        }
        return deck
    }

    mutating func drawCard() -> Card {
        let count = self.count
        let index = Int.random(in: 0...(count - 1))
        let card = self[index]
        remove(at: index)
        return card
    }

}
