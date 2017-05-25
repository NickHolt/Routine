//
//  DailyActivitiesViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit
import os.log

class DailyActivitiesViewController: UITableViewController {
    
    let log = OSLog(subsystem: "com.redox.Routine", category: "DailyActivitiesViewController")
    
    @IBOutlet var yesterdayButton: UIBarButtonItem!
    @IBOutlet var tomorrowButton: UIBarButtonItem!
    @IBOutlet var addActivityButton: UIBarButtonItem!
    
    var activityStore: ActivityStore!
    var currentActivities: [Activity]!
    var completedActivities = Set<Activity>()
    var excusedActivities = Set<Activity>()
    
    var allCurrentActivitiesComplete: Bool {
        return completedActivities.count == currentActivities.count
    }
    var allCurrentActivitiesCompleteOrExcused: Bool {
        return completedActivities.count + excusedActivities.count == currentActivities.count
    }
    
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
    
    let tapGenerator = UIImpactFeedbackGenerator(style: .heavy)

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
        var newTitle: String
        
        if displayedDateIsToday {
            newTitle = "Today"
        } else {
            newTitle = titleDateFormatter.string(from: displayedDate)
        }
        
        let completeBadge = "🌟"
        let completeWithExcusedBadge = "⭐️"
        if currentActivities.count > 0 && allCurrentActivitiesComplete {
            newTitle += " \(completeBadge)"
        } else if currentActivities.count > 0 && allCurrentActivitiesCompleteOrExcused {
            newTitle += " \(completeWithExcusedBadge)"
        } else {
            newTitle = newTitle.replacingOccurrences(of: completeBadge, with: "")
            newTitle = newTitle.replacingOccurrences(of: completeWithExcusedBadge, with: "")
        }
        
        navigationItem.title = newTitle
    }
    
    fileprivate func load(with date: Date) {
        os_log("Loading Activities for date: %f", log: log, type: .debug, date.timeIntervalSinceReferenceDate)
        
        displayedDate = date
        
        currentActivities = activityStore.getActivities(for: date)
        currentActivities.sort {
            activityA, activityB -> Bool in
            
            return activityA.title ?? "" < activityB.title ?? ""
        }
        
        // Populate from ActivityStore
        os_log("Removing %d completed and %d excused Activities from current view", log: log, type: .debug, completedActivities.count, excusedActivities.count)

        completedActivities.removeAll()
        excusedActivities.removeAll()
        for activity in currentActivities {
            var completion = activityStore.getCompletion(for: activity, on: displayedDate)
            if completion == nil {
                os_log("No Completion data found for Activity: %@. Adding a non-completion.", log: log, type: .debug, activity)
                completion = activityStore.registerCompletion(for: activity, on: date, withStatus: .notCompleted)
            }
            
            switch completion!.status {
            case .completed:
                completedActivities.insert(activity)
            case .excused:
                excusedActivities.insert(activity)
            case .notCompleted:
                break
            }
        }
        
        os_log("Fetched %d completed and %d excused Activities", log: log, type: .debug, completedActivities.count, excusedActivities.count)
        
        configureBarButtonItems()
        configureTitle()
        
        os_log("Preparing tap generator", log: log, type: .debug)
        tapGenerator.prepare()
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        load(with: Date())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        leftEdgePan.edges = .left
        
        view.addGestureRecognizer(leftEdgePan)
        
        let rightEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        rightEdgePan.edges = .right
        
        view.addGestureRecognizer(rightEdgePan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleDoubleTapped))
        tap.numberOfTapsRequired = 2
        tap.numberOfTouchesRequired = 2
        
        view.addGestureRecognizer(tap)
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
    
    fileprivate func setStreak(for cell: DailyActivitiesViewCell, withDataFrom activity: Activity) {
        guard let activityStreak = try? activityStore.getCompletionStreak(for: activity, endingOn: displayedDate, withPreviousFallback: displayedDateIsToday) else {
            cell.currentStreak.text = "Unknown Streak"
            return
        }
        
        cell.currentStreak.text = "\(activityStreak) Day Streak"
    }
    
    fileprivate func setCompletionStatus(forActivityAt indexPath: IndexPath, status: Completion.Status) {
        let activity = self.activity(for: indexPath)
        
        os_log("Setting completion status of Activity: %@ to %d", log: log, type: .debug, activity, status.rawValue)

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
        
        let cell = tableView.cellForRow(at: indexPath) as! DailyActivitiesViewCell
        
        setStreak(for: cell, withDataFrom: activity)
        format(cell: cell, forCompletionStatus: status)
        configureTitle()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        os_log("Add Activity shortcut pressed", log: log, type: .debug)
        
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
        return tableView.dequeueReusableCell(withIdentifier: "DailyActivitiesViewCell", for: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activity = self.activity(for: indexPath)
        
        if completedActivities.contains(activity) {
            setCompletionStatus(forActivityAt: indexPath, status: .notCompleted)
        } else {
            setCompletionStatus(forActivityAt: indexPath, status: .completed)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        configureTitle()
        
        if allCurrentActivitiesCompleteOrExcused {
            os_log("Requesting impact haptic", log: log, type: .debug)
            tapGenerator.impactOccurred()
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let activity = self.activity(for: indexPath)
        
        let myCell = cell as! DailyActivitiesViewCell
        myCell.activityTitle.text = activity.title
        setStreak(for: myCell, withDataFrom: activity)

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

// MARK: Gesture Recognition
extension DailyActivitiesViewController {
    func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard recognizer.state == .recognized else {
            return
        }
        
        switch recognizer.edges {
        case [.left]:
            os_log("Left edge pan recognized", log: log, type: .debug)
            load(with: dateDayBefore)
        case [.right]:
            guard !displayedDateIsToday else {
                return
            }
            os_log("Right edge pan recognized", log: log, type: .debug)
            load(with: dateDayAfter)
        default:
            preconditionFailure("Unrecognized edge pan gesture for edges: \(recognizer.edges)")
        }
    }
    
    func doubleDoubleTapped() {
        os_log("Double-double tap recognized", log: log, type: .debug)
        load(with: Date())
    }
}
