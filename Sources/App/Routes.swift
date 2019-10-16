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

protocol EncodablePage: Encodable {
    var route: String { get }
    var description: String { get }
    var title: String { get }
}

extension EncodablePage {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: PageCodingKeys.self)
        try container.encode(route, forKey: .route)
        try container.encode(description, forKey: .description)
        try container.encode(title, forKey: .title)
    }
}

extension MainController {

    enum Page: EncodablePage {
        // Pages
        case index

        // Database
        case database

        // Commands
        case kill
        case casters
        case clients
        case state

        var route: String {
            switch self {
            case .index: return ""
            case .database: return "database"
            case .casters: return "casters"
            case .clients: return "clients"
            case .kill: return "kill"
            case .state: return "state"
            }
        }

        var description: String {
            switch self {
            case .index: return "The home page."
            case .database: return "Player database"
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
            case .index: return "Home"
            case .database: return "database"
            }
        }
    }

    typealias Params<T> = [String: T] where T: Encodable

    func routes(_ router: Router) throws {
        weak var `self` = self

        router.get { (req) -> Future<View> in
            return try req.view().render("index", [
                "commands": [Page.casters, Page.clients, Page.database, Page.kill],
                "database": [Page.database]
            ])
        }

        // Database
        router.get(Page.database.route) { [weak self] (req) -> Future<View> in
            let promise = req.sharedContainer.eventLoop.newPromise(View.self)
            DatabaseController.getPlayers(on: req).addAwaiter(callback: { (result) in
                if let players = result.result,
                    let view = try? req.view().render("database", ["players": players]) {
                    view.addAwaiter(callback: { (result) in
                        if let view = result.result {
                            promise.succeed(result: view)
                        } else if let error = result.error {
                            print(error.localizedDescription)
                            promise.fail(error: error)
                        } else {
                            promise.fail(error: DatabaseError.BadRender)
                        }
                    })
                } else {
                    promise.fail(error: DatabaseError.BadRender)
                }
            })
            return promise.futureResult
        }

        // Commands
        func resultViewRenderer(for command: (() -> String)?) -> (Request) throws -> Future<View> {
            return { (req) -> Future<View> in
                return try req.view().render("result", ["result": command?() ?? "☢️ BAD ☢️"])
            }
        }
        router.get(Page.kill.route, use: resultViewRenderer(for: self?.killGame))
        router.get(Page.casters.route, use: resultViewRenderer(for: self?.getCasters))
        router.get(Page.clients.route, use: resultViewRenderer(for: self?.getClients))
        router.get(Page.state.route, use: resultViewRenderer(for: self?.getState))
    }

}
