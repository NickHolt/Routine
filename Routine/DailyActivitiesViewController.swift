//
//  DailyActivitiesViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

class DailyActivitiesViewController: UITableViewController {
    
    var activityStore: ActivityStore!
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityStore.numTotalActivities
    }
    
}
