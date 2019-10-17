import Vapor
import Leaf
import FluentSQLite

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    let controller = MainController()
    try services.register(controller)

    // MARK: WebSockets
    let wss = NIOWebSocketServer.default()
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

    // MARK: SQLite
    try services.register(FluentSQLiteProvider())
    let sqlite = try SQLiteDatabase(storage: .memory)
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)
    var migrations = MigrationConfig()
    migrations.add(model: SQLitePlayer.self, database: .sqlite)
    services.register(migrations)

}
