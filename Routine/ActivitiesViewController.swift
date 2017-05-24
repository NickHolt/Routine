//
//  ActivitiesViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit
import os.log

class ActivitiesViewController: UITableViewController {
    
    let log = OSLog(subsystem: "com.redox.Routine", category: "ActivitiesViewController")
    
    var activityStore: ActivityStore!
    var displayedActivities: [Activity]!
    
    var searchController: UISearchController!
    
    private func activity(for indexPath: IndexPath) -> Activity {
        return displayedActivities[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedActivities.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Sort displayed activities
        displayedActivities = activityStore.allActivities
        displayedActivities.sort {
            activityA, activityB -> Bool in
            
            return activityA.title ?? "" < activityB.title ?? ""
        }
        
        // Configure search
        if displayedActivities.count > 0 {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            
            searchController.searchBar.sizeToFit()
            tableView.tableHeaderView = searchController.searchBar
            
            definesPresentationContext = true
            
            // Hide search bar by default
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Grab cell for re-use
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivitiesViewCell", for: indexPath) as! ActivitiesViewCell
        
        // Populate cell
        let activity = self.activity(for: indexPath)
        
        os_log("Retrieved Activity: %@ for cell at row: %d", log: log, type: .debug, activity, indexPath.row)
        
        cell.activityTitle.text = activity.title
        cell.daysOfWeek.text = string(for: activity.daysOfWeek)
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailViewController = segue.destination as! ActivityDetailViewController
        detailViewController.activityStore = activityStore
        
        os_log("Segue triggered: %s", log: log, type: .debug, segue.identifier ?? "Unknown")
        
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
            
            os_log("User indicated deletion for Activity: %@", log: log, type: .debug, activity)
            
            try? activityStore.remove(activity: activity)
            if let activityIndex = displayedActivities.index(of: activity) {
                displayedActivities.remove(at: activityIndex)
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

extension ActivitiesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        
        os_log("User searching Activities for: %s", log: log, type: .debug, searchText)
        
        displayedActivities = searchText.isEmpty ? activityStore.allActivities : activityStore.allActivities.filter {
                activity -> Bool in
            
            return activity.title?.range(of: searchText, options: .caseInsensitive) != nil
        }
        
        tableView.reloadData()
    }
}
