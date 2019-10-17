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
        case takings

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
            case .takings: return "takings"
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
            case .takings: return "The total takings by the house."
            }
        }

        var title: String {
            switch self {
            case .casters: return "Get Casters"
            case .clients: return "Get Clients"
            case .state: return "Get State"
            case .kill: return "Kill Game"
            case .index: return "Home"
            case .database: return "Database"
            case .takings: return "Total Takings"
            }
        }
    }

    struct Context<T: Encodable>: Encodable {
        let commands = [Page.casters, Page.clients, Page.state, Page.kill]
        let database = [Page.database, Page.takings]
        let values: [String: T]?
        init(values: [String: T]? = nil) {
            self.values = values
        }

        func renderer(forTemplate template: String) -> Renderer {
            return { (req) -> Future<View> in
                return try req.view().render(template, self)
            }
        }
    }

    typealias Renderer = (Request) throws -> Future<View>

    func routes(_ router: Router) throws {
        weak var `self` = self

        func resultViewRenderer(for command: (() -> String)?) -> Renderer {
            return { (req) -> Future<View> in
                return try req.view().render(
                    "result",
                    Context(values: ["result": command?() ?? "☢️ BAD ☢️"])
                )
            }
        }

        func renderAwaiter(promise: EventLoopPromise<View>) -> (FutureResult<View>) -> Void {
            return { (result) in
                if let view = result.result {
                    promise.succeed(result: view)
                } else if let error = result.error {
                    print(error.localizedDescription)
                    promise.fail(error: error)
                } else {
                    promise.fail(error: DatabaseError.BadRender)
                }
            }
        }

        // Index
        router.get("", use: Context<String>().renderer(forTemplate: "index"))

        router.get { (req) -> Future<View> in
            let promise = req.sharedContainer.eventLoop.newPromise(View.self)
            let alert = !(self?.clientPool.clients.isEmpty ?? true) ?
                "A game is in progress!" : nil
            if let renderer = try? Context(values: ["alert": alert]).renderer(
                forTemplate: "index"
                )(req) {
                renderer.addAwaiter(callback: renderAwaiter(promise: promise))
            } else {
                promise.fail(error: DatabaseError.BadRender)
            }
            return promise.futureResult
        }

        // Database
        router.get(Page.database.route) { (req) -> Future<View> in
            let promise = req.sharedContainer.eventLoop.newPromise(View.self)
            DatabaseController.getPlayers(on: req).addAwaiter(callback: { (result) in
                guard let players = result.result,
                    let renderer = try? Context(
                        values: ["players": players]
                        ).renderer(
                            forTemplate: "database"
                        )(req) else {
                            promise.fail(error: DatabaseError.BadRender); return
                }
                renderer.addAwaiter(callback: renderAwaiter(promise: promise))
            })
            return promise.futureResult
        }
        router.get(Page.takings.route) { (req) -> Future<View> in
            let promise = req.sharedContainer.eventLoop.newPromise(View.self)
            DatabaseController.getPlayers(on: req).addAwaiter(callback: { (result) in
                guard let players = result.result else {
                    promise.fail(error: DatabaseError.BadRender); return
                }
                guard let renderer = try? resultViewRenderer(for: { () -> String in
                    let takings = -(players.reduce(0, { (result, player) -> Int in
                        return result + player.winnings
                    }))
                    return "£\(takings / 100)"
                })(req) else {
                    promise.fail(error: DatabaseError.BadRender); return
                }
                renderer.addAwaiter(callback: renderAwaiter(promise: promise))
            })
            return promise.futureResult
        }

        // Commands
        router.get(Page.kill.route, use: resultViewRenderer(for: self?.killGame))
        router.get(Page.casters.route, use: resultViewRenderer(for: self?.getCasters))
        router.get(Page.clients.route, use: resultViewRenderer(for: self?.getClients))
        router.get(Page.state.route, use: resultViewRenderer(for: self?.getState))
    }

}
