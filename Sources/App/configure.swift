import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // WebSockets
    let wss = NIOWebSocketServer.default()
    let controller = MainController()
    wss.get("player", String.parameter) { ws, req in
        let name = try req.parameters.next(String.self)
        controller.clientPool.setup(webSocket: ws, withName: name)
    }
    wss.get("caster") { (ws, _) in
        controller.casterPool.setup(webSocket: ws)
    }
    services.register(wss, as: WebSocketServer.self)

    // Commands
    var commandConfig = CommandConfig.default()
    commandConfig.use(State(mainController: controller), as: "state")
    services.register(commandConfig)

}
