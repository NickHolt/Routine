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
    
    convenience init(random: Bool = false) {
        if !random {
            self.init(name: "", daysOfWeek: [])
            return
        }
        
        let verbs = ["Jump", "Read", "Exercise"]
        let randomVerb = verbs[Int(arc4random_uniform(UInt32(verbs.count)))]

        let places = ["In the sky", "At home", "En la playa"]
        let randomPlace = places[Int(arc4random_uniform(UInt32(places.count)))]
        
        let randomDaysOfWeek = [
            DayOfWeek(rawValue: UInt8(1 << arc4random_uniform(7))),
            DayOfWeek(rawValue: UInt8(1 << arc4random_uniform(7))),
        ]
        
        self.init(name: "\(randomVerb) \(randomPlace)", daysOfWeek: randomDaysOfWeek as! [DayOfWeek])
    }
}
