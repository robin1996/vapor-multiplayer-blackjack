import Vapor
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // MARK: WebSockets
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

    // MARK: Leaf
    try services.register(LeafProvider())
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)

    // MARK: Router
    let router = EngineRouter.default()
    try controller.routes(router)
    services.register(router, as: Router.self)

}
