//
//  GameController.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 08/10/2019.
//

import Vapor

protocol GameControllerDelegate: AnyObject {
    func gameStarted(with clients: Clients, gameController: GameController)
    func gameEnded(with clients: Clients, gameController: GameController)
}

class GameController {

    private let gameLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
    private var deck: Deck = []
    private var clients: Clients
    private var turn = 0 {
        didSet {
            round = roundFor(turn: turn)
        }
    }
    private var round = 0
    private var client: ClientController {
        return clients[Int(turn % clients.count)]
    }
    weak var delegate: GameControllerDelegate?

    init(clients: Clients, delegate: GameControllerDelegate) {
        self.clients = clients
        self.delegate = delegate
    }

    func start() {
        turn = 0
        deck = Deck.standard()
        clearHands()
        delegate?.gameStarted(with: clients, gameController: self)
        takeStake()
    }

    func end() {
        try! gameLoop.close()
        delegate?.gameEnded(with: clients, gameController: self)
    }

    // MARK: - GamePlay

    private func takeStake() {
        print("🤑 Requesting stake from \(client.player.username)")
        try! client.request(
            actions: [.stake],
            withType: .inProgress,
            onLoop: gameLoop
        ).addAwaiter { [weak client, weak self] (result) in
            guard let client = client, let self = self else { print("☢️ GAME OR CLIENT DEAD ☢️"); return }
            guard result.result??.action == .stake, let value = result.result??.value else {
                print("⚠️ BAD STAKE RESPONSE ⚠️"); return
            }
            print("💸 Staking \(value)p")
            client.player.hands = [Hand(stake: value)]
            try! client.request(
                actions: [],
                withType: .waiting,
                onLoop: self.gameLoop
            ).always {
                self.turn += 1
                if self.turn >= self.clients.count {
                    self.takeTurn()
                } else {
                    self.takeStake()
                }
            }
        }
    }

    private func takeTurn() {
        let hand = client.player.hands[0]
        guard handStillInPlay(hand) else {
            print("⏩ Skipping \(client.player.username)")
            if roundFor(turn: turn + 1) > round && isGameOver() { // `roundFor`
                                                                 // stops `isGa-
                                                                 // meOver` from
                                                                 // being called
                                                                 // more than o-
                                                                 // nce a round.
                completeGame()
            } else {
                nextTurn()
            }
            return
        }
        guard hand.cards.count >= 2 else {
            print("🃏 Dealing to \(client.player.username)")
            hand.cards.append(self.deck.drawCard())
            try! client.request(
                actions: [],
                withType: .waiting,
                onLoop: gameLoop
            ).always {
                // Artificial delay
                self.gameLoop.scheduleTask(in: TimeAmount.seconds(1)) {
                    self.nextTurn()
                }
            }
            return
        }
        print("🤞 Requesting action from \(client.player.username)")
        try! client.request(
            actions: [.hit, .stand],
            withType: .inProgress,
            onLoop: gameLoop
        ).addAwaiter(callback: { [weak self] (result) in
            guard let self = self else { print("☢️ GAME DEAD ☢️"); return }
            guard let action = result.result??.action else { print("⚠️ BAD RESPONSE ⚠️"); return }
            print("👌 Executing response instruction \(action.rawValue)")
            switch action {
            case .hit:
                self.hit()
            case .stand:
                self.stand()
            case .split, .double:
                print("⚠️ UNSUPPORTED ACTION ⚠️"); fallthrough
            case .stake:
                print("⚠️ UNEXPECTED STAKE ⚠️"); fallthrough
            default:
                self.takeTurn()
            }
        })
    }

    private func completeGame() {
        clients.forEach { (client) in
            let hand = client.player.hands[0]
            _ = try! client.request(
                actions: [],
                withType: hand.lowTotal <= 21 ? .win : .lose,
                onLoop: self.gameLoop
            )
        }
        gameLoop.scheduleTask(in: TimeAmount.seconds(5)) { [weak self] in
            guard let self = self else { print("☢️ GAME DEAD ☢️"); return }
            self.clients.forEach({ _ = try! $0.request(
                actions: [],
                withType: .ended,
                onLoop: self.gameLoop
            ) })
            self.gameLoop.scheduleTask(in: TimeAmount.seconds(2)) { [weak self] in
                self?.start()
            }
        }
    }

    // MARK: Actions

    private func hit() {
        let hand = client.player.hands[0]
        hand.cards.append(self.deck.drawCard())
        try! client.request(
            actions: [],
            withType: hand.lowTotal > 21 ? .bust : .waiting,
            onLoop: gameLoop
        ).always { [weak self] in
            self?.nextTurn()
        }
    }

    private func stand() {
        let hand = client.player.hands[0]
        hand.hasStood = true
        try! client.request(
            actions: [],
            withType: .waiting,
            onLoop: gameLoop
        ).always { [weak self] in
            self?.nextTurn()
        }
    }

    // MARK: Helpers

    private func nextTurn() {
        self.turn += 1
        self.takeTurn()
    }

    /// Check is if hand is still in play (not bust or 21).
    ///
    /// - Parameter hand: Hand to check.
    /// - Returns: True if the hand is still in play.
    private func handStillInPlay(_ hand: Hand) -> Bool {
        return hand.lowTotal < 21 && !hand.hasStood
    }

    /// Checks if the game is over.
    ///
    /// - Returns: True if the game is over.
    private func isGameOver() -> Bool {
        return !clients.reduce(false) { (inPlay, client) -> Bool in
            inPlay || client.player.hands.reduce(false, { (inPlay, hand) -> Bool in
                inPlay || self.handStillInPlay(hand)
            })
        }
    }

    private func roundFor(turn: Int) -> Int {
        return Int(floor(Double(turn) / Double(clients.count)))
    }

    private func clearHands() {
        clients.forEach { (client) in
            client.player.hands = []
        }
    }

}
