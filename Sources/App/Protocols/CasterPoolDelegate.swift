//
//  CasterPoolDelegate.swift
//  App
//
//  Created by Robin Douglas on 11/10/2019.
//

import Vapor

protocol CasterPoolDelegate: AnyObject {
    func casterConnected(_ socket: WebSocket)
}
