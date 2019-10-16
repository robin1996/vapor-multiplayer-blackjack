//
//  SQLitePlayer.swift
//  App
//
//  Created by Robin Douglas on 15/10/2019.
//

import FluentSQLite

struct SQLitePlayer: SQLiteStringModel, SQLiteMigration {
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
}
