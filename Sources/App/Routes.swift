//
//  Routes.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 14/10/2019.
//

import Vapor

enum DatabaseError: Error {
    case NoDatabase
    case BadRender
}

enum PageCodingKeys: String, CodingKey {
    case route, description, title
}

protocol Page: Encodable {
    var route: String { get }
    var description: String { get }
    var title: String { get }
}

extension Page {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PageCodingKeys.self)
        try container.encode(route, forKey: .route)
        try container.encode(description, forKey: .description)
        try container.encode(title, forKey: .title)
    }
}

extension MainController {

    enum Location: Page {
        case index
        case database

        var route: String {
            switch self {
            case .index: return ""
            case .database: return "database"
            }
        }

        var description: String {
            switch self {
            case .index: return "The home page."
            case .database: return "Player database"
            }
        }

        var title: String {
            switch self {
            case .index: return "Home"
            case .database: return "database"
            }
        }
    }

    enum Command: Page, CaseIterable {
        case kill
        case casters
        case clients
        case state

        var route: String {
            switch self {
            case .casters: return "casters"
            case .clients: return "clients"
            case .kill: return "kill"
            case .state: return "state"
            }
        }

        var description: String {
            switch self {
            case .casters: return "List of the currently connected casters."
            case .clients: return "List of the currently connected clients."
            case .state: return "The current game state."
            case .kill: return "Kill the current game."
            }
        }

        var title: String {
            switch self {
            case .casters: return "Get Casters"
            case .clients: return "Get Clients"
            case .state: return "Get State"
            case .kill: return "Kill Game"
            }
        }
    }

    func routes(_ router: Router) throws {
        weak var `self` = self

        router.get { (req) -> Future<View> in
            return try req.view().render("index", ["pages": Command.allCases])
        }

        router.get(Location.database.route) { (req) -> Future<View> in
            let promise = req.sharedContainer.eventLoop.newPromise(View.self)
            SQLitePlayer.query(on: req).all().addAwaiter(callback: { (result) in
                guard let players = result.result else {
                    promise.fail(error: DatabaseError.NoDatabase); return
                }
                let text = players.reduce("", { (result, player) -> String in
                    return "\(result)\(player.username ?? "N/a")\t\(player.winnings)\n"
                })
                guard let view = try? req.view().render("result", ["result": text]) else {
                    promise.fail(error: DatabaseError.BadRender); return
                }
                view.addAwaiter(callback: { (result) in
                    guard let view = result.result else {
                        promise.fail(error: DatabaseError.BadRender); return
                    }
                    promise.succeed(result: view)
                })
            })
            return promise.futureResult
        }

        // Commands
        func resultViewRenderer(for command: (() -> String)?) -> (Request) throws -> Future<View> {
            return { (req) -> Future<View> in
                return try req.view().render("result", ["result": command?() ?? "☢️ BAD ☢️"])
            }
        }
        router.get(Command.kill.route, use: resultViewRenderer(for: self?.killGame))
        router.get(Command.casters.route, use: resultViewRenderer(for: self?.getCasters))
        router.get(Command.clients.route, use: resultViewRenderer(for: self?.getClients))
        router.get(Command.state.route, use: resultViewRenderer(for: self?.getState))
    }

}
