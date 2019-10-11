//
//  ClientPoolDelegate.swift
//  App
//
//  Created by Robin Douglas on 11/10/2019.
//

import Foundation

protocol ClientPoolDelegate: AnyObject {
    func clientConnected(_ client: ClientController)
    func clientDisconnected(_ client: ClientController?)
}
