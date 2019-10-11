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

typealias Players = [Player]

class GameController {

    private let gameLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
    private var deck: Deck = []
    private var players: Players {
        return clients + [dealer]
    }
    private var clients: Clients
    private let dealer = Dealer()
    private var turn = 0 {
        didSet {
            round = roundFor(turn: turn)
        }
    }
    private var round = 0

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
        print("🏁 Game started")
        // Get stakes and set off game
        players.forEach { takeStake(fromPlayer: $0) }
    }

    func end() {
        try! gameLoop.close()
        delegate?.gameEnded(with: clients, gameController: self)
    }

    // MARK: - GamePlay

    private func takeStake(fromPlayer player: Player) {
        print("🤑 Requesting stake from \(player.model.username)")
        try! player.request(
            actions: [.stake],
            withType: .inProgress,
            onLoop: gameLoop
        ).addAwaiter(callback: { [weak player, weak self] (result) in
            guard let player = player else {
                print("☢️ MISSING PLAYER ☢️"); return
            }
            guard let value = result.result??.value else {
                print("🥺 Missing stake")
                self?.takeStake(fromPlayer: player)
                return
            }
            self?.stake(amount: value, forPlayer: player)
        })
    }

    private func takeTurn() {
        let currentPlayer = player(forTurn: turn)
        guard let hand = currentPlayer.hand else {
            print("☣️ MISSING HAND ☢️"); return
        }
        guard handStillInPlay(hand) else {
            print("⏩ Skipping \(currentPlayer.model.username)")
            if roundFor(turn: turn + 1) > round && isGameOver() { // `roundFor`
                                                                 // stops `isGa-
                                                                 // meOver` from
                                                                 // being called
                                                                 // more than o-
                                                                 // nce a round.
                completeGame()
            } else {
                wait(
                    currentPlayer,
                    causeBust: currentPlayer.hand?.bestTotal() ?? 0 > 21
                )
            }
            return
        }
        guard hand.cards.count >= 2 else {
            print("🃏 Dealing to \(currentPlayer.model.username)")
            hand.cards.append(self.deck.drawCard())
            try! currentPlayer.request(
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
        print("🙏 Requesting action from \(currentPlayer.model.username)")
        try! currentPlayer.request(
            actions: [.hit, .stand],
            withType: .inProgress,
            onLoop: gameLoop
        ).addAwaiter(callback: gameAwaiter(result:))
    }

    private func gameAwaiter(result: FutureResult<PlayerResponse?>) {
        weak var `self` = self
        guard let currentPlayer = self?.player(forTurn: turn) else {
            print("☢️ GAME DEAD ☢️"); return
        }
        guard let action = result.result??.action else {
            print("⚠️ BAD RESPONSE ⚠️"); self?.takeTurn(); return
        }
        print("💪 Executing response instruction \(action.rawValue)")
        switch action {
        case .hit:
            self?.hit(currentPlayer)
        case .stand:
            self?.stand(currentPlayer)
        case .stake:
            print("⚠️ UNSUPPORTED STAKE ⚠️"); fallthrough
        case .split, .double:
            print("⚠️ UNSUPPORTED ACTION ⚠️"); fallthrough
        default:
            self?.takeTurn()
        }
    }

    private func completeGame() {
        players.forEach { (client) in
            _ = try! client.request(
                actions: [],
                withType: client.hand?.lowTotal() ?? 0 > 21 ?
                    .bust : client.hand!.beatsDealers(
                        hand: dealer.hand!
                    ) ? .win : .lose,
                onLoop: self.gameLoop
            )
        }
        gameLoop.scheduleTask(in: TimeAmount.seconds(5)) { [weak self] in
            guard let self = self else { print("☢️ GAME DEAD ☢️"); return }
            print("🎬 Game ended")
            self.players.forEach({ _ = try! $0.request(
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

    // Setup

    private func stake(amount: Int, forPlayer player: Player) {
        print("💸 Staking \(amount)p")
        #warning("Will need to change if we allow multiple hands.")
        player.model.hands = [Hand(stake: amount)]
        try! player.request(
            actions: [],
            withType: .waiting,
            onLoop: self.gameLoop
        ).always {
            if self.allStakesMade() {
                self.takeTurn()
            }
        }
    }

    // Play

    private func hit(_ player: Player) {
        player.hand?.cards.append(self.deck.drawCard())
        try! player.request(
            actions: [],
            withType: player.hand?.lowTotal() ?? 0 > 21 ? .bust : .waiting,
            onLoop: gameLoop
        ).always { [weak self] in
            self?.takeTurn()
        }
    }

    private func stand(_ player: Player) {
        player.hand?.hasStood = true; #warning("Should this be a member of `Player`?")
        try! player.request(
            actions: [],
            withType: .waiting,
            onLoop: gameLoop
        ).always { [weak self] in
            self?.nextTurn()
        }
    }

    private func wait(_ player: Player, causeBust bust: Bool = false) {
        print("⏱ Telling \(player.model.username) to wait")
        try! player.request(
            actions: [],
            withType: bust ? .bust : .waiting,
            onLoop: gameLoop
        ).always {
            self.nextTurn()
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
        return hand.lowTotal() < 21 && !hand.hasStood
    }

    /// Checks if the game is over.
    ///
    /// - Returns: True if the game is over.
    private func isGameOver() -> Bool {
        return !players.reduce(false) { (inPlay, client) -> Bool in
            inPlay || client.model.hands.reduce(false, { (inPlay, hand) -> Bool in
                inPlay || self.handStillInPlay(hand)
            })
        }
    }

    private func roundFor(turn: Int) -> Int {
        return Int(floor(Double(turn) / Double(players.count)))
    }

    private func clearHands() {
        players.forEach { (client) in
            client.model.hands = []
        }
    }

    /// Check that ever player has made a stake by making sure they have atleast
    /// one hand.
    ///
    /// - Returns: True if every player has made a stake.
    private func allStakesMade() -> Bool {
        return players.reduce(true, { (allStaked, player) -> Bool in
            return allStaked && player.hand != nil
        })
    }

    private func player(forTurn turn: Int) -> Player {
         return players[Int(turn % players.count)]
    }

}
