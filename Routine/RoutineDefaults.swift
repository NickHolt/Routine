//
//  RoutineDefaults.swift
//  Routine
//
//  Created by Nick Holt on 6/12/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation

class RoutineDefaults {
    
    private static let defaults = UserDefaults.standard
    
    private static let lastActiveDefaultsKey = "lastActive"

    static func getLastActive() -> Date? {
        return defaults.object(forKey: lastActiveDefaultsKey) as? Date
    }
    
    static func recordLastActive() {
        defaults.set(Date(), forKey: lastActiveDefaultsKey)
    }
}
