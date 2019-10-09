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
    private var turn = 0
    private var client: ClientController {
        return clients[Int(Double(turn).truncatingRemainder(dividingBy: Double(clients.count)))]
    }
    weak var delegate: GameControllerDelegate?

    init(clients: Clients, delegate: GameControllerDelegate) {
        self.clients = clients
        self.delegate = delegate
    }

    func start() {
        deck = Deck.standard()
        delegate?.gameStarted(with: clients, gameController: self)
        takeStake()
    }

    func end() {
        try! gameLoop.close()
        delegate?.gameEnded(with: clients, gameController: self)
    }

    // MARK: - GamePlay

    private func takeStake() {
        print("💸 Requesting stake from \(client.player.username)")
        try! client.request(actions: [.stake], withType: .inProgress, onLoop: gameLoop).addAwaiter { [weak client, weak self] (result) in
            guard let client = client, let self = self else { print("☢️ GAME OR CLIENT DEAD ☢️"); return }
            guard result.result??.action == .stake, let value = result.result??.value else {
                print("⚠️ BAD STAKE RESPONSE ⚠️"); return
            }
            print("🤑 Staking \(value)p")
            client.player.hands = [Hand(stake: value)]
            try! client.request(actions: [], withType: .waiting, onLoop: self.gameLoop).always {
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
            nextTurn()
            return
        }
        guard hand.cards.count >= 2 else {
            print("🃏 Dealing to \(client.player.username)")
            hand.cards.append(self.deck.drawCard())
            try! client.request(
                actions: [],
                withType: .waiting,
                onLoop: gameLoop
            ).always { [weak self] in
                self?.nextTurn()
            }
            return
        }
        print("🤞 Requesting action from \(client.player.username)")
        try! client.request(
            actions: [.hit],
            withType: .inProgress,
            onLoop: gameLoop
        ).addAwaiter(callback: { [weak self] (result) in
            guard let self = self else { print("☢️ GAME DEAD ☢️"); return }
            guard let action = result.result??.action else { print("⚠️ BAD RESPONSE ⚠️"); return }
            print("👌 Executing response instruction \(action.rawValue)")
            switch action {
            case .hit:
                self.hit()
            case .split, .double, .stand:
                print("⚠️ UNSUPPORTED ACTION ⚠️"); fallthrough
            case .stake:
                print("⚠️ UNEXPECTED STAKE ⚠️"); fallthrough
            default:
                self.takeTurn()
            }
        })
    }

    // MARK: Actions

    func hit() {
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

    // MARK: Helpers

    func nextTurn() {
        self.turn += 1
        self.takeTurn()
    }

    /// Check is if hand is still in play (not bust or 21).
    ///
    /// - Parameter hand: Hand to check.
    /// - Returns: True if the hand is still in play.
    func handStillInPlay(_ hand: Hand) -> Bool {
//        return hand.lowTotal < 21
        return true
    }

}
