//
//  ActivityStore.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

class ActivityStore {
    var allActivities = [Activity]()
    var numTotalActivities: Int {
        get {
            return allActivities.count
        }
    }
    
    @discardableResult func createActivity() -> Activity {
        let newActivity = Activity(random: true)

        allActivities.append(newActivity)

        return newActivity
    }
    
    init() {
        for _ in 0..<5 {
            createActivity()
        }
    }
}
