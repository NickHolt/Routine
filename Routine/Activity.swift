//
//  Activity.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation

class Activity: NSObject {
    var name: String
    var daysOfWeek: UInt8
    
    init(name: String, daysOfWeek: UInt8) {
        self.name = name
        self.daysOfWeek = daysOfWeek
    }
}
