//
//  State.swift
//  App
//
//  Created by Robin Douglas on 14/10/2019.
//

import Command

struct GetState: Command {

    weak var mainController: MainController?
    var arguments: [CommandArgument] {
        return []
    }
    var options: [CommandOption] {
        return []
    }
    var help: [String] {
        return ["Gets the current game state."]
    }

    init(mainController: MainController) {
        self.mainController = mainController
    }

    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        var result = "No game 🥺"
        if let data = try? BlackjackEncoder().encode(mainController?.gameController.getGameState()),
            let string = String(data: data, encoding: .utf8) {
            result = string
        }
        context.console.print(result)
        return .done(on: context.container)
    }

}
