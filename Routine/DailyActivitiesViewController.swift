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
    var currentActivities: [Activity]!
    var completedActivities = Set<Activity>()
    
    var displayedDate: Date!
    var displayedDateIsToday: Bool {
        return Calendar.current.isDate(displayedDate, inSameDayAs: Date())
    }
    var dateDayBefore: Date! {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -1, to: displayedDate)
    }
    var dateDayAfter: Date! {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: displayedDate)
    }
    
    let titleDateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, yyyy"
        
        return dateFormatter
    }()
    let buttonDateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        
        return dateFormatter
    }()

    fileprivate func activity(for indexPath: IndexPath) -> Activity {
        return currentActivities[indexPath.row]
    }
    
    fileprivate func configureBarButtonItems() {
        if displayedDateIsToday {
            self.navigationItem.rightBarButtonItems = [addActivityButton]
        } else {
            self.navigationItem.rightBarButtonItems = [tomorrowButton]
        }
        
        yesterdayButton.title = "< \(buttonDateFormatter.string(from: dateDayBefore))"
        tomorrowButton.title = "\(buttonDateFormatter.string(from: dateDayAfter)) >"
    }
    
    fileprivate func configureTitle() {
        if displayedDateIsToday {
            self.navigationItem.title = "Today"
        } else {
            self.navigationItem.title = titleDateFormatter.string(from: displayedDate)
        }
    }
    
    fileprivate func load(with date: Date) {
        displayedDate = date

        let dayOfWeek = Calendar(identifier: .gregorian).dayOfWeek(from: date)
        currentActivities = activityStore.activities(for: dayOfWeek)
        currentActivities.sort {
            activityA, activityB -> Bool in
            
            return activityA.title ?? "" < activityB.title ?? ""
        }
        
        // Populate completedActivities from ActivityStore
        completedActivities.removeAll()
        for activity in currentActivities {
            guard let completionStatus = activityStore.getCompletion(for: activity, on: displayedDate)?.status, completionStatus == .completed else {
                print("\(String(describing: activity.title)). \(String(describing: activityStore.getCompletion(for: activity, on: displayedDate)?.status))")
                continue
            }
            
            print("\(String(describing: activity.title)). \(String(describing: activityStore.getCompletion(for: activity, on: displayedDate)?.status))")


            completedActivities.insert(activity)
        }
        
        configureBarButtonItems()
        configureTitle()
        
        tableView.reloadData()
    }
    
    @IBAction func viewDayBefore(_ sender: UIBarButtonItem) {
        load(with: dateDayBefore)
    }
    
    @IBAction func viewDayAfter(_ sender: UIBarButtonItem) {
        load(with: dateDayAfter)
    }
}

// MARK: UITableViewController methods
extension DailyActivitiesViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentActivities.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        load(with: Date())
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
        
        if completedActivities.contains(activity) {
            completedActivities.remove(activity)
            activityStore.registerCompletion(for: activity, on: displayedDate, withStatus: .notCompleted)
        } else {
            completedActivities.insert(activity)
            activityStore.registerCompletion(for: activity, on: displayedDate, withStatus: .completed)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let activity = self.activity(for: indexPath)
        
        if completedActivities.contains(activity) {
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let activity = self.activity(for: indexPath)
        
        let archiveAction = UITableViewRowAction(style: .normal, title: "Excuse") { action, index in
            print("Excusing \(activity)!")
        }
        archiveAction.backgroundColor = .lightGray
        
        return [archiveAction]
    }
}
