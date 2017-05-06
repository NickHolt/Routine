//
//  Activity.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation

enum DayOfWeek: UInt8 {
    case Monday    = 1
    case Tuesday   = 2
    case Wednesday = 4
    case Thursday  = 8
    case Friday    = 16
    case Saturday  = 32
    case Sunday    = 64
}

class Activity: NSObject {
    var name: String
    var daysOfWeek: [DayOfWeek]
    
    init(name: String, daysOfWeek: [DayOfWeek]) {
        self.name = name
        self.daysOfWeek = daysOfWeek
    }
}
