//
//  Coding.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 08/10/2019.
//

import Foundation

class BlackjackEncoder: JSONEncoder {
    override init() {
        super.init()
        keyEncodingStrategy = .convertToSnakeCase
    }
}

class BlackjackDecoder: JSONDecoder {
    override init() {
        super.init()
        keyDecodingStrategy = .convertFromSnakeCase
    }
}
