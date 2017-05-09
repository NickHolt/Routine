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

    @discardableResult func createActivity(random: Bool = true) -> Activity {
        let newActivity = Activity(random: random)

        allActivities.append(newActivity)

        return newActivity
    }
    
    init() {
        for _ in 0..<5 {
            createActivity()
        }
    }
}
