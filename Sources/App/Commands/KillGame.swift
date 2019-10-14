//
//  KillGame.swift
//  App
//
//  Created by Robin Douglas on 14/10/2019.
//

import Command

struct KillGame: Command {

    weak var mainController: MainController?
    var arguments: [CommandArgument] {
        return []
    }
    var options: [CommandOption] {
        return []
    }
    var help: [String] {
        return ["Ends the current game."]
    }

    init(mainController: MainController) {
        self.mainController = mainController
    }

    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        mainController?.gameController.end()
        context.console.print("Done 👍")
        return .done(on: context.container)
    }

}
