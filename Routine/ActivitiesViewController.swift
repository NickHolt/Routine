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
    var completionHistory: CompletionHistory!
    
    var activeActivities: [Activity]!
    var inactiveActivities: [Activity]!
    
    var searchController: UISearchController!
    
    private func activity(for indexPath: IndexPath) -> Activity {
        if indexPath.section == 0 {
            return activeActivities[indexPath.row]
        } else {
            return inactiveActivities[indexPath.row]
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return inactiveActivities.count > 0 ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return activeActivities.count
        } else {
            return inactiveActivities.count
        }
    }
    
    private func activity(_ firstActivity: Activity, shouldAppearBefore secondActivity: Activity) -> Bool {
        guard let firstTitle = firstActivity.title else {
            return false
        }
        guard let secondTitle = secondActivity.title else {
            return true
        }
        
        return firstTitle < secondTitle
    }
    
    fileprivate func refreshActiveActivities() {
        activeActivities = Array(activityStore.getAllActiveActivities())
        activeActivities = activeActivities.sorted(by: activity(_:shouldAppearBefore:))
    }
    
    fileprivate func refreshInactiveActivities() {
        inactiveActivities = Array(activityStore.getAllInactiveActivities())
        inactiveActivities = inactiveActivities.sorted(by: activity(_:shouldAppearBefore:))
    }
    
    fileprivate func refreshActivities() {
        refreshActiveActivities()
        refreshInactiveActivities()
    }
    
    private func configureForSearch() {
        guard activeActivities.count + inactiveActivities.count > 0 else {
            return
        }
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.sizeToFit()
        tableView.tableHeaderView = searchController.searchBar
        
        definesPresentationContext = true
        
        // Hide search bar by default
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refreshActivities()
        
        configureForSearch()
        
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    private func configure(cell: ActivitiesViewCell, for activity: Activity) {
        cell.activityTitle.text = activity.title
        cell.daysOfWeek.text = string(for: activity.daysOfWeek)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivitiesViewCell", for: indexPath) as! ActivitiesViewCell
        
        let activity = self.activity(for: indexPath)
        os_log("Retrieved Activity: %@ for cell at row: %d", log: log, type: .debug, activity, indexPath.row)
        
        configure(cell: cell, for: activity)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard numberOfSections(in: tableView) > 1 else {
            return nil
        }
        
        switch section {
        case 0:
            return "Active Activities"
        case 1:
            return "Archived Activities"
        default:
            return nil
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailViewController = segue.destination as! ActivityDetailViewController
        detailViewController.activityStore = activityStore
        detailViewController.completionHistory = completionHistory
        
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
}

extension ActivitiesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        
        os_log("User searching Activities for: %s", log: log, type: .debug, searchText)
        
        refreshActivities()
        if !searchText.isEmpty {
            let containsText: (Activity) -> Bool = {
                return $0.title?.range(of: searchText, options: .caseInsensitive) != nil
            }
            
            activeActivities = activeActivities.filter(containsText)
            inactiveActivities = activeActivities.filter(containsText)
        }
        
        tableView.reloadData()
    }
}
