//
//  DailyActivitiesViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

class DailyActivitiesViewController: UITableViewController {
    
    @IBOutlet var yesterdayButton: UIBarButtonItem!
    @IBOutlet var tomorrowButton: UIBarButtonItem!
    @IBOutlet var addActivityButton: UIBarButtonItem!
    
    var activityStore: ActivityStore!
    var todaysActivities: [Activity]!
    var completedActivities = [Activity]()
    
    var displayedDate: Date!
    
    private func activity(for indexPath: IndexPath) -> Activity {
        return todaysActivities[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todaysActivities.count
    }
    
    private func configureBarButtonItems() {
        if Calendar.current.isDate(displayedDate, inSameDayAs: Date()) {
            self.navigationItem.rightBarButtonItems = [addActivityButton]
        } else {
            self.navigationItem.rightBarButtonItems = [tomorrowButton]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        todaysActivities = activityStore.todaysActivities()
        displayedDate = Date()
        
        configureBarButtonItems()
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Grab cell for re-use
        let cell = tableView.dequeueReusableCell(withIdentifier: "DailyActivitiesViewCell", for: indexPath) as! DailyActivitiesViewCell
        
        // Populate cell
        let activity = self.activity(for: indexPath)
        
        cell.activityTitle.text = activity.title
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity = self.activity(for: indexPath)
        
        if let activityIndex = completedActivities.index(of: activity) {
            completedActivities.remove(at: activityIndex)
        } else {
            completedActivities.append(activity)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let activity = self.activity(for: indexPath)
        
        if completedActivities.index(of: activity) != nil {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailViewController = segue.destination as! ActivityDetailViewController
        detailViewController.activityStore = activityStore
    }
}
