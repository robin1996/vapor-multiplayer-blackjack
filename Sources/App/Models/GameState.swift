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

struct Hand: Codable {
    enum TotalType: String, Codable {
        case hard, soft
    }
    
    let id: Int
    var cards: [Card]
    var totalType: TotalType
    var total: String = ""
    var stake: Int
    var winnings: Int

    func getTotal() -> String {
        let lowTotal = cards.sum { (card) -> Int in
            card.lowValue
        }
        let hightTotal = cards.sum { (card) -> Int in
            card.highValue
        }
        if hightTotal == 21 && cards.count == 2 {
            return "Blackjack"
        }
        if hightTotal != lowTotal {
            return "\(hightTotal)/\(lowTotal)"
        }
        return "\(hightTotal)"
    }
    
    mutating func updateTotal() {
        total = getTotal()
    }
}

struct Player: Codable {
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
