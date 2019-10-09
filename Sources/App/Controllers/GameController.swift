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
        clients.forEach { (client) in
            #warning("Dummy")
            client.player.hands = [DummyData.hand]
        }
        deck = Deck.standard()
        delegate?.gameStarted(with: clients, gameController: self)
        takeTurn()
    }
    
    func end() {
        try! gameLoop.close()
        delegate?.gameEnded(with: clients, gameController: self)
    }
    
    private func takeTurn() {
        let client = self.client
        print("🤞 Requesting action from \(client.player.username)")
        (try! client.request(
            actions: [.hit],
            withType: .inProgress,
            onLoop: gameLoop
            )).addAwaiter { [weak self] (result) in
                guard let self = self else { return }
                if let unwrap = result.result, let result = unwrap {
                    print("🤩 Got a response!!!")
                    switch result.action {
                    case .double: break
                    case .hit:
                        client.player.hands[0].cards.append(self.deck.drawCard())
                    case .split: break
                    case .stake: break
                    case .stand: break
                    }
                } else {
                    print("🤔 no response, were they asked for an action?")
                }
                self.turn += 1
                self.takeTurn()
        }
        
    }
    
}
