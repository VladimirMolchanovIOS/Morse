//
//  Extensions.swift
//  Morse
//
//  Created by Владимир Молчанов on 13/09/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import Foundation

prefix operator ~
prefix func ~(key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

extension Array {
    mutating func addNewElementBetweenElements(newElement element: Element) {
        var c = 1
        for _ in (self.startIndex..<(self.endIndex - 1)) {
            self.insert(element, at: c)
            c = c + 2
        }
    }
}


extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (key, value) in pairs {
            self.updateValue(value, forKey: key)
        }
    }
}
