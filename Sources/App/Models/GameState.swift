//
//  Card.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 07/10/2019.
//

import Foundation

enum Suit: String, Encodable, CaseIterable {
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

enum Rank: String, Encodable, CaseIterable {
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

struct Card: Encodable {
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
    var lowValue: Int {
        switch rank {
        case .ace: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 8
        case .nine: return 9
        case .ten: return 10
        case .jack: return 10
        case .queen: return 10
        case .king: return 10
        }
    }
    var highValue: Int {
        if rank == .ace {
            return 11
        }
        return lowValue
    }
}

class Hand: Encodable {
    enum TotalType: String, Codable {
        case hard, soft
    }

    enum CodingKeys: String, CodingKey {
        case cards, totalType, stake, winnings, total
    }

    var cards: [Card] = []
    var totalType: TotalType = .soft
    var stake: Int
    var winnings: Int = 0
    var hasStood = false // Shouldn't be encoded
    var total: String {
        let lowTotal = self.lowTotal
        let hightTotal = cards.sum { (card) -> Int in
            card.highValue
        }
        if hightTotal == 21 && cards.count == 2 {
            return "Blackjack"
        }
        if hightTotal > 21 {
            return "\(lowTotal)"
        }
        if hightTotal != lowTotal {
            return "\(lowTotal)/\(hightTotal)"
        }
        return "\(hightTotal)"
    }
    var lowTotal: Int {
        return cards.sum({ (card) -> Int in
            card.lowValue
        })
    }

    init(stake: Int) {
        self.stake = stake
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cards, forKey: .cards)
        try container.encode(totalType, forKey: .totalType)
        try container.encode(stake, forKey: .stake)
        try container.encode(winnings, forKey: .winnings)
        try container.encode(total, forKey: .total)
    }
}

class PlayerModel: Encodable {
    let username: String
    var hands: [Hand] = []
    var insurance: Int = 0
    var winnings: Int {
        return hands.sum { (hand) -> Int in
            return hand.winnings
        }
    }

    init(username: String) {
        self.username = username
    }
}

//struct GameState: Encodable {
//    var players: [Player]
//    var currentPlayer: Player
//    var dealer: Player
//}

enum PlayerAction: String, Codable {
    case hit, stand, double, split, stake
}

struct PlayerResponse: Decodable {
    let action: PlayerAction
    var value: Int?
}

struct PlayerRequest: Encodable {
    enum RequestType: String, Codable {
        case waiting, ended, inProgress, bust, win, lose
    }

    let actions: [PlayerAction]
    let type: RequestType
    let player: PlayerModel
}
