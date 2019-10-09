import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // Set host name and port
    let serverConfiure = NIOServerConfig.default(hostname: "0.0.0.0", port: 9002)
    services.register(serverConfiure)

    // WebSockets
    let wss = NIOWebSocketServer.default()
    let controller = ClientPoolController()
    wss.get("player", String.parameter) { ws, req in
        let name = try req.parameters.next(String.self)
        ws.send("Hello \(name)")
        controller.setup(webSocket: ws, withName: name)
    }
    services.register(wss, as: WebSocketServer.self)

}
