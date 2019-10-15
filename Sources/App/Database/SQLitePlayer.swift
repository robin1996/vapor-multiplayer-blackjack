//
//  SQLitePlayer.swift
//  App
//
//  Created by Robin Douglas on 15/10/2019.
//

import FluentSQLite

final class SQLitePlayer: SQLiteStringModel, SQLiteMigration {
    var id: String? {
        get {
            return username
        }
        set {
            username = newValue
        }
    }
    var username: String?
    var winnings: Int

    init(username: String, winnings: Int) {
        self.username = username; self.winnings = winnings
    }
}
