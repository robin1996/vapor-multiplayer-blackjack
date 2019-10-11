//
//  GameControllerDelegate.swift
//  App
//
//  Created by Robin Douglas on 11/10/2019.
//

import Foundation

protocol GameControllerDelegate: AnyObject {
    func gameStarted(with clients: Clients, gameController: GameController)
    func gameEnded(with clients: Clients, gameController: GameController)
}
