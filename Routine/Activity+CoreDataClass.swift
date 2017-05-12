//
//  Activity+CoreDataClass.swift
//  Routine
//
//  Created by Nick Holt on 5/11/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation
import CoreData

@objc(Activity)
public class Activity: NSManagedObject {
    var daysOfWeek: [DayOfWeek]?
    
//    init(title: String, daysOfWeek: [DayOfWeek], uuid: UUID) {
//        super.init(
//        
//        self.title = title
//        self.daysOfWeek = daysOfWeek
//        self.uuid = uuid
//    }
//    
//    convenience init() {
//        self.init(title: "New Activity", daysOfWeek: [], uuid: UUID())
//    }
//    
//    convenience init(random: Bool) {
//        if !random {
//            self.init()
//            return
//        }
//        
//        let verbs = ["Jump", "Read", "Exercise"]
//        let randomVerb = verbs[Int(arc4random_uniform(UInt32(verbs.count)))]
//        
//        let places = ["In the sky", "At home", "En la playa"]
//        let randomPlace = places[Int(arc4random_uniform(UInt32(places.count)))]
//        
//        let randomDaysOfWeek = [
//            DayOfWeek(rawValue: Int(arc4random_uniform(7))),
//            DayOfWeek(rawValue: Int(arc4random_uniform(7))),
//            ]
//        
//        self.init(
//            title: "\(randomVerb) \(randomPlace)",
//            daysOfWeek: randomDaysOfWeek as! [DayOfWeek],
//            uuid: UUID()
//        )
//    }
}
