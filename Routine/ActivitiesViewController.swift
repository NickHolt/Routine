//
//  ActivitiesViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

class ActivitiesViewController: UITableViewController {
    
    var activityStore: ActivityStore!
    var displayedActivities = [Activity]()
    
    private func activity(for indexPath: IndexPath) -> Activity {
        return activityStore.allActivities[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityStore.allActivities.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        displayedActivities = activityStore.allActivities
        displayedActivities.sort {
            activityA, activityB -> Bool in
            
            return activityA.title ?? "" < activityB.title ?? ""
        }
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Grab cell for re-use
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivitiesViewCell", for: indexPath) as! ActivitiesViewCell
        
        // Populate cell
        let activity = self.activity(for: indexPath)
        
        cell.activityTitle.text = activity.title
        cell.daysOfWeek.text = string(for: activity.daysOfWeek)
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailViewController = segue.destination as! ActivityDetailViewController
        detailViewController.activityStore = activityStore
        
        switch segue.identifier {
        case "addNewActivity"?:
            // Nothing to do
            break
        case "showActivityDetail"?:
            guard let indexPath = tableView.indexPathForSelectedRow else {
                preconditionFailure("No index path available for selected row")
            }
            detailViewController.activity = self.activity(for: indexPath)
        default:
            preconditionFailure("Unexpected segue identifier")
        }        
    }
    
    @IBAction func toggleEditingMode(_ sender: UIBarButtonItem) {
        if isEditing {
            sender.title = "Edit"
            setEditing(false, animated: true)
        } else {
            sender.title = "Done"
            setEditing(true, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let activity = self.activity(for: indexPath)
            
            try? activityStore.remove(activity: activity)
            if let activityIndex = displayedActivities.index(of: activity) {
                displayedActivities.remove(at: activityIndex)
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
