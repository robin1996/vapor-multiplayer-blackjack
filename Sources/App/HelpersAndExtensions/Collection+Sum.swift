//
//  Collection+Sum.swift
//  ./Multiplayer-BlackjackPackageDescription
//
//  Created by Robin Douglas on 08/10/2019.
//

import Foundation

extension Collection {
    func sum<T: Numeric>(_ numericMemberOfElement: (_ element: Element) -> T) -> T {
        return reduce(into: T.zero) { (total, element) in
            total += numericMemberOfElement(element)
        }
    }
}
