//
//  Activity.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation

class Activity: NSObject {
    var title: String
    var daysOfWeek: [DayOfWeek]
    var uuid: UUID
    
    init(title: String, daysOfWeek: [DayOfWeek], uuid: UUID) {
        self.title = title
        self.daysOfWeek = daysOfWeek
        self.uuid = uuid
    }
    
    convenience init(random: Bool = false) {
        if !random {
            self.init(title: "", daysOfWeek: [], uuid: UUID())
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
        
        self.init(
            title: "\(randomVerb) \(randomPlace)",
            daysOfWeek: randomDaysOfWeek as! [DayOfWeek],
            uuid: UUID()
        )
    }
}
