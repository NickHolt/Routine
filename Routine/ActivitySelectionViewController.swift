//
//  ActivitySelectionViewController.swift
//  Routine
//
//  Created by Nick Holt on 6/1/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit
import os.log

class ActivitySelectionViewController: UITableViewController {
    var activityStore: ActivityStore!
    var activities: [Activity]!
    
    private func activity(_ firstActivity: Activity, shouldAppearBefore secondActivity: Activity) -> Bool {
        guard let firstTitle = firstActivity.title?.lowercased() else {
            return false
        }
        guard let secondTitle = secondActivity.title?.lowercased() else {
            return true
        }
        
        return firstTitle < secondTitle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activities = activityStore.getAllActiveActivities().sorted(by: activity(_:shouldAppearBefore:))
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let activity = activities[indexPath.row]
        
        cell.textLabel?.text = activity.title
    }
}
