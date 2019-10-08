//
//  Card.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 07/10/2019.
//

import Foundation

enum Suit: String, Codable, CaseIterable {
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

enum Rank: String, Codable, CaseIterable {
    case ace = "A"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case ten = "10"
    case jack = "J"
    case queen = "Q"
    case king = "K"
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

struct Hand: Codable {
    enum TotalType: String, Codable {
        case hard, soft
    }

    let id: Int
    var cards: [Card]
    var totalType: TotalType
    var total: Int
    var stake: Int
    var winnings: Int
}

struct Player: Codable {
    let username: String
    var hands: [Hand] = []
    var insurance: Int = 0
    var winnings: Int {
        return hands.reduce(0) { (total, hand) -> Int in
            total + hand.winnings
        }
    }

    init(username: String) {
        self.username = username
    }
}

struct GameState: Codable {
    var players: [Player]
    var currentPlayer: Player
    var dealer: Player
}

enum PlayerAction: String, Codable {
    case hit, stand, double, split, stake
}

struct PlayerResponse: Codable {
    let action: PlayerAction
    var value: Int?
}

struct PlayerRequest: Codable {
    enum RequestType: String, Codable {
        case waiting, ended, inProgress
    }

    let actions: [PlayerAction]
    let type: RequestType
    let player: Player
}