import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // Set host name and port
//    let serverConfiure = NIOServerConfig.default(hostname: "0.0.0.0", port: 9001)
//    services.register(serverConfiure)

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

}
