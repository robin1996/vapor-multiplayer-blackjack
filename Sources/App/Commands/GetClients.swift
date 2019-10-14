//
//  Clients.swift
//  App
//
//  Created by Robin Douglas on 14/10/2019.
//

import Command

struct GetClients: Command {

    weak var mainController: MainController?
    var arguments: [CommandArgument] {
        return []
    }
    var options: [CommandOption] {
        return []
    }
    var help: [String] {
        return ["Gets a list of clients in the client pool."]
    }

    init(mainController: MainController) {
        self.mainController = mainController
    }

    func run(using context: CommandContext) throws -> EventLoopFuture<Void> {
        context.console.print(mainController?.clientPool.clients.reduce("", { (text, client) -> String in
            return "\(text)\(client.model)\t\(String(describing: client.socket))\n"
        }) ?? "")
        return .done(on: context.container)
    }

}
