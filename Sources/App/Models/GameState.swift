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

class Hand {
    enum TotalType: String, Codable {
        case hard, soft
    }

    var cards: [Card] = []
    var totalType: TotalType = .soft
    var stake: Int
    var hasStood = false // Shouldn't be encoded

    init(stake: Int) {
        self.stake = stake
    }

    func lowTotal() -> Int {
        return cards.sum { (card) -> Int in
            card.lowValue
        }
    }

    func highTotal() -> Int {
        return cards.sum { (card) -> Int in
            card.highValue
        }
    }

    func total() -> (low: Int, high: Int) {
        return (low: lowTotal(), high: highTotal())
    }

    func bestTotal() -> Int {
        let total = self.total()
        return total.high <= 21 ? total.high : total.low
    }

    func beatsDealers(hand: Hand) -> Bool {
        let total = self.bestTotal()
        let dealerTotal = hand.bestTotal()
        guard total <= 21 else {
            return false
        }
        if dealerTotal > 21 || (total == 21 && hand.cards.count > 2 && cards.count == 2) {
            return true
        }
        return total > dealerTotal
    }

}

extension Hand: Encodable {
    enum CodingKeys: String, CodingKey {
        case cards, totalType, stake, winnings, total
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cards, forKey: .cards)
        try container.encode(totalType, forKey: .totalType)
        try container.encode(stake, forKey: .stake)
        var totalString = ""
        let total = self.total()
        switch total.high {
        case 21:
            guard cards.count == 2 else { fallthrough }
            totalString = "Blackjack"
        case ...21:
            totalString = "\(total.low != total.high ? "\(total.low)/" : "")\(total.high)"
        default:
            totalString = "\(total.low)"
        }
        try container.encode(totalString, forKey: .total)
    }
}

class PlayerModel: Encodable {
    enum PlayerStatus: String, Codable {
        case waiting, ended, inProgress, bust, win, lose
    }

    let username: String
    var status = PlayerStatus.waiting
    var hands: [Hand] = []
    var insurance: Int = 0
    var winnings: Int = 0

    init(username: String) {
        self.username = username
    }

    init?(sqliteModel: SQLitePlayer) {
        guard let name = sqliteModel.username else { return nil }
        username = name
        winnings = sqliteModel.winnings
    }

    func sqliteModel() -> SQLitePlayer {
        return SQLitePlayer(username: username, winnings: winnings)
    }
}

struct GameState: Encodable {
    var players: [PlayerModel]
    var dealer: PlayerModel
}

enum PlayerAction: String, Codable {
    case hit, stand, double, split, stake
}

struct PlayerResponse: Decodable {
    let action: PlayerAction
    var value: Int?
}

struct PlayerRequest: Encodable {
    let actions: [PlayerAction]
    let player: PlayerModel
}
