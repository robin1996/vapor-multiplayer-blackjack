//
//  Card.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 07/10/2019.
//

import Foundation

enum Suit: String, Codable {
    case spades, hearts, diamonds, clubs

    var symbol: Character {
        switch self {
        case .spades:
            return "♠"
        case .hearts:
            return "♥"
        case .diamonds:
            return "♦"
        case .clubs:
            return "♣"
        }
    }
}

enum Rank: String, Codable {
    case ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king
}

enum Colour: String {
    case black, red
}

struct Card: Codable {
    let suit: Suit
    let rank: Rank
    var colour: Colour {
        switch suit {
        case .hearts, .diamonds:
            return .red
        case .clubs, .spades:
            return .black
        }
    }
}
