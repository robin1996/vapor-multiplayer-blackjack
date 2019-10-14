//
//  GetCasters.swift
//  App
//
//  Created by Robin Douglas on 14/10/2019.
//

import Command

struct GetCasters: Command {

    weak var mainController: MainController?
    var arguments: [CommandArgument] {
        return []
    }
    var options: [CommandOption] {
        return []
    }
    var help: [String] {
        return ["Gets a list of casters in the caster pool."]
    }

    init(mainController: MainController) {
        self.mainController = mainController
    }

    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        context.console.print(mainController?.casterPool.casters.reduce("", { (text, caster) -> String in
            return "\(text)\(String(describing: caster))\n"
        }) ?? "")
        return .done(on: context.container)
    }

}
