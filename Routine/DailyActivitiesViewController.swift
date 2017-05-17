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
    var excusedActivities = Set<Activity>()
    
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
        
        // Populate from ActivityStore
        completedActivities.removeAll()
        excusedActivities.removeAll()
        for activity in currentActivities {
            guard let completionStatus = activityStore.getCompletion(for: activity, on: displayedDate)?.status else {
                continue
            }
            
            switch completionStatus {
            case .completed:
                completedActivities.insert(activity)
            case .excused:
                excusedActivities.insert(activity)
            case .notCompleted:
                break
            }
        }
        
        configureBarButtonItems()
        configureTitle()
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        load(with: Date())
    }
    
    @IBAction func viewDayBefore(_ sender: UIBarButtonItem) {
        load(with: dateDayBefore)
    }
    
    @IBAction func viewDayAfter(_ sender: UIBarButtonItem) {
        load(with: dateDayAfter)
    }
    
    fileprivate func format(cell: UITableViewCell, forCompletionStatus status: Completion.Status) {
        switch status {
        case .completed:
            cell.accessoryType = .checkmark
            cell.backgroundColor = nil
        case .excused:
            cell.accessoryType = .none
            cell.backgroundColor = .lightGray
        case .notCompleted:
            cell.accessoryType = .none
            cell.backgroundColor = nil
        }
    }
    
    fileprivate func setCompletionStatus(forActivityAt indexPath: IndexPath, status: Completion.Status) {
        let activity = self.activity(for: indexPath)

        switch status {
        case .completed:
            completedActivities.insert(activity)
            excusedActivities.remove(activity)

            activityStore.registerCompletion(for: activity, on: displayedDate, withStatus: .completed)
        case .excused:
            completedActivities.remove(activity)
            excusedActivities.insert(activity)
            
            activityStore.registerCompletion(for: activity, on: displayedDate, withStatus: .excused)
        case .notCompleted:
            completedActivities.remove(activity)
            excusedActivities.remove(activity)

            activityStore.registerCompletion(for: activity, on: displayedDate, withStatus: .notCompleted)
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        format(cell: cell, forCompletionStatus: status)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let detailViewController = segue.destination as! ActivityDetailViewController
        detailViewController.activityStore = activityStore
    }
}

// MARK: UITableViewController methods
extension DailyActivitiesViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentActivities.count
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
            setCompletionStatus(forActivityAt: indexPath, status: .notCompleted)
        } else {
            setCompletionStatus(forActivityAt: indexPath, status: .completed)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let activity = self.activity(for: indexPath)
        if completedActivities.contains(activity) {
            format(cell: cell, forCompletionStatus: .completed)
        } else if excusedActivities.contains(activity) {
            format(cell: cell, forCompletionStatus: .excused)
        } else {
            format(cell: cell, forCompletionStatus: .notCompleted)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let activity = self.activity(for: indexPath)
        
        var archiveAction: UITableViewRowAction
        if !excusedActivities.contains(activity) {
            archiveAction = UITableViewRowAction(style: .normal, title: "Excuse") { action, index in
                self.setCompletionStatus(forActivityAt: index, status: .excused)
                tableView.setEditing(false, animated: true)
            }
            archiveAction.backgroundColor = .lightGray
        } else {
            archiveAction = UITableViewRowAction(style: .normal, title: "Revive") { action, index in
                self.setCompletionStatus(forActivityAt: index, status: .notCompleted)
                tableView.setEditing(false, animated: true)
            }
            archiveAction.backgroundColor = .green
        }
        
        return [archiveAction]
    }
}
