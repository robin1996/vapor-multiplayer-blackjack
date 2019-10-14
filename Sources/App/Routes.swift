//
//  Routes.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 14/10/2019.
//

import Vapor

extension MainController {

    enum Pages: CaseIterable, Encodable {
        enum CodingKeys: String, CodingKey {
            case route, description, title
        }

        case index
        case kill
        case casters
        case clients
        case state

        var route: String {
            switch self {
            case .index: return ""
            case .casters: return "casters"
            case .clients: return "clients"
            case .kill: return "kill"
            case .state: return "state"
            }
        }

        var description: String {
            switch self {
            case .index: return "The home page."
            case .casters: return "List of the currently connected casters."
            case .clients: return "List of the currently connected clients."
            case .state: return "The current game state."
            case .kill: return "Kill the current game."
            }
        }

        var title: String {
            switch self {
            case .index: return "Home"
            case .casters: return "Get Casters"
            case .clients: return "Get Clients"
            case .state: return "Get State"
            case .kill: return "Kill Game"
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(route, forKey: .route)
            try container.encode(description, forKey: .description)
            try container.encode(title, forKey: .title)
        }
    }

    func routes(_ router: Router) throws {
        weak var `self` = self
        func resultViewRenderer(for command: (() -> String)?) -> (Request) throws -> Future<View> {
            return { (req) -> Future<View> in
                return try req.view().render("result", ["result": command?() ?? "☢️ BAD ☢️"])
            }
        }
        router.get { (req) -> Future<View> in
            return try req.view().render("index", ["pages": Pages.allCases])
        }
        router.get("kill", use: resultViewRenderer(for: self?.killGame))
        router.get("casters", use: resultViewRenderer(for: self?.getCasters))
        router.get("clients", use: resultViewRenderer(for: self?.getClients))
        router.get("state", use: resultViewRenderer(for: self?.getState))
    }

}
