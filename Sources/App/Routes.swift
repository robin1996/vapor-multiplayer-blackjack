//
//  Routes.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 14/10/2019.
//

import Vapor

extension MainController {

    func routes(_ router: Router) throws {
        weak var `self` = self
        func resultViewRenderer(for command: (() -> String)?) -> (Request) throws -> Future<View> {
            return { (req) -> Future<View> in
                return try req.view().render("result", ["result": command?() ?? "☢️ BAD ☢️"])
            }
        }
        router.get { (req) -> Future<View> in
            return try req.view().render("index")
        }
        router.get("kill", use: resultViewRenderer(for: self?.killGame))
        router.get("casters", use: resultViewRenderer(for: self?.getCasters))
        router.get("clients", use: resultViewRenderer(for: self?.getClients))
        router.get("state", use: resultViewRenderer(for: self?.getState))
    }

}
