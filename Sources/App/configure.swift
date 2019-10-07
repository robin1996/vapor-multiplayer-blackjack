import FluentSQLite
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    // Set host name and port
    let serverConfiure = NIOServerConfig.default(hostname: "0.0.0.0", port: 9001)
    services.register(serverConfiure)
    
    // WebSockets
    let wss = NIOWebSocketServer.default()
    let controller = GameController()
    wss.get("echo") { ws, req in
        controller.setup(webSocket: ws)
    }
    services.register(wss, as: WebSocketServer.self)
    
    // MARK: - Default
    
//    // Register providers first
//    try services.register(FluentSQLiteProvider())
//
//    // Register routes to the router
//    let router = EngineRouter.default()
//    try routes(router)
//    services.register(router, as: Router.self)
//
//    // Register middleware
//    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
//    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
//    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
//    services.register(middlewares)
//
//    // Configure a SQLite database
//    let sqlite = try SQLiteDatabase(storage: .memory)
//
//    // Register the configured SQLite database to the database config.
//    var databases = DatabasesConfig()
//    databases.add(database: sqlite, as: .sqlite)
//    services.register(databases)
//
//    // Configure migrations
//    var migrations = MigrationConfig()
//    migrations.add(model: Todo.self, database: .sqlite)
//    services.register(migrations)
}
