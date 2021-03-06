//
//  DailyActivitiesViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit
import os.log

protocol ActivityOccurrenceHandler {
    func addActivityOccurrence(activity: Activity)
}

class DailyActivitiesViewController: UITableViewController {
    
    let log = OSLog(subsystem: "com.redox.Routine", category: "DailyActivitiesViewController")
    
    @IBOutlet var yesterdayButton: UIBarButtonItem!
    @IBOutlet var tomorrowButton: UIBarButtonItem!
    @IBOutlet var addActivityButton: UIBarButtonItem!
    
    var activityStore: ActivityStore!
    var completionStore: CompletionStore!
    var completionHistory: CompletionHistory!

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
    
    private func getDateTitle() -> String {
        if displayedDateIsToday {
            return "Today"
        } else {
            return titleDateFormatter.string(from: displayedDate)
        }
    }
    
    private func setBadge(forTitle title: String) -> String {
        var newTitle = title
        
        let completeBadge = "🌟"
        let completeWithExcusedBadge = "⭐️"
        
        newTitle = newTitle.replacingOccurrences(of: completeBadge, with: "")
        newTitle = newTitle.replacingOccurrences(of: completeWithExcusedBadge, with: "")

        if currentActivities.count > 0 && allCurrentActivitiesComplete {
            newTitle += " \(completeBadge)"
        } else if currentActivities.count > 0 && allCurrentActivitiesCompleteOrExcused {
            newTitle += " \(completeWithExcusedBadge)"
        }

        return newTitle
    }
    
    private func requestImpactIfNeeded() {
        if allCurrentActivitiesCompleteOrExcused {
            os_log("Requesting impact haptic", log: log, type: .debug)
            tapGenerator.impactOccurred()
        }
    }
    
    fileprivate func configureTitle() {
        var title = getDateTitle()
        title = setBadge(forTitle: title)
        
        navigationItem.title = title
    }
    
    fileprivate func configureNavigationItem() {
        configureBarButtonItems()
        configureTitle()
    }
    
    fileprivate func getAllActivities(for date: Date) -> Set<Activity> {
        let allCompletions = completionStore.getAllCompletions(for: date)
        let activitiesFromCompletions = Set(allCompletions.filter { $0.activity != nil }.map { $0.activity! })
        
        let activitiesFromDate = activityStore.getActivities(for: date)
        
        return activitiesFromCompletions.union(activitiesFromDate)
    }
    
    private func refreshCurrentActivities(for date: Date) {
        currentActivities = Array(getAllActivities(for: date))
        currentActivities.sort {
            activityA, activityB -> Bool in
            
            return activityA.title ?? "" < activityB.title ?? ""
        }
    }
    
    private func sortCurrentActivities() {
        os_log("Removing %d completed and %d excused Activities from current view", log: log, type: .debug, completedActivities.count, excusedActivities.count)
        
        completedActivities.removeAll()
        excusedActivities.removeAll()
        for activity in currentActivities {
            var completion = completionHistory.getCompletion(for: activity, on: displayedDate)
            if completion == nil {
                os_log("No Completion data found for Activity: %@. Adding a non-completion.", log: log, type: .debug, activity)
                completion = completionHistory.registerCompletion(for: activity, on: displayedDate, withStatus: .notCompleted)
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
        
        os_log("Sorted into %d completed and %d excused Activities", log: log, type: .debug, completedActivities.count, excusedActivities.count)
    }
    
    fileprivate func load(for date: Date) {
        os_log("Loading Activities for date: %f", log: log, type: .debug, date.timeIntervalSinceReferenceDate)
        
        displayedDate = date
        
        refreshCurrentActivities(for: date)
        
        sortCurrentActivities()
        
        configureNavigationItem()
        
        os_log("Preparing tap generator", log: log, type: .debug)
        tapGenerator.prepare()
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        load(for: Date())
    }
    
    private func configureEdgePanGestures() {
        let leftEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        leftEdgePan.edges = .left
        
        view.addGestureRecognizer(leftEdgePan)
        
        let rightEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        rightEdgePan.edges = .right
        
        view.addGestureRecognizer(rightEdgePan)
    }
    
    private func configureTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleDoubleTapped))
        tap.numberOfTapsRequired = 2
        tap.numberOfTouchesRequired = 2
        
        view.addGestureRecognizer(tap)
    }
    
    @objc private func applicationWillEnterForeground() {
        os_log("Entered foreground", log: log, type: .debug)
        
        if shouldRefreshToToday() {
            load(for: Date())
        } else {
            load(for: displayedDate)
        }
    }
    
    func shouldRefreshToToday() -> Bool {
        guard let lastTerminated = RoutineDefaults.getLastActive() else {
            return true
        }
        
        return !dateIsInSameDayAsToday(lastTerminated) && !dateIsWithin(nHours: 1, date: lastTerminated)
    }
    
    func dateIsInSameDayAsToday(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    func dateIsWithin(nHours n: Int, date: Date) -> Bool {
        return abs(getHourFrom(date: date) - getHourFrom(date: Date())) <= n
    }
    
    func getHourFrom(date: Date) -> Int {
        return Calendar.current.component(.hour, from: date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        configureEdgePanGestures()
        
        configureTapGesture()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil )
    }
    
    @IBAction func viewDayBefore(_ sender: UIBarButtonItem) {
        load(for: dateDayBefore)
    }
    
    @IBAction func viewDayAfter(_ sender: UIBarButtonItem) {
        load(for: dateDayAfter)
    }
    
    fileprivate func format(cell: UITableViewCell, forCompletionStatus status: Completion.Status) {
        switch status {
        case .completed:
            cell.accessoryType = .checkmark
            cell.backgroundColor = .white
        case .excused:
            cell.accessoryType = .none
            cell.backgroundColor = .lightGray
        case .notCompleted:
            cell.accessoryType = .none
            cell.backgroundColor = .white
        }
    }
    
    fileprivate func setStreak(for cell: DailyActivitiesViewCell, withDataFrom activity: Activity) {
        guard let activityStreak = try? completionHistory.getCompletionStreak(for: activity, endingOn: displayedDate, withPreviousFallback: displayedDateIsToday) else {
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

            completionHistory.registerCompletion(for: activity, on: displayedDate, withStatus: .completed)
        case .excused:
            completedActivities.remove(activity)
            excusedActivities.insert(activity)
            
            completionHistory.registerCompletion(for: activity, on: displayedDate, withStatus: .excused)
        case .notCompleted:
            completedActivities.remove(activity)
            excusedActivities.remove(activity)

            completionHistory.registerCompletion(for: activity, on: displayedDate, withStatus: .notCompleted)
        }
        
        let cell = tableView.cellForRow(at: indexPath) as! DailyActivitiesViewCell
        
        setStreak(for: cell, withDataFrom: activity)
        format(cell: cell, forCompletionStatus: status)
        configureTitle()
        requestImpactIfNeeded()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case "showActivitySelection":
            os_log("Add Activity occurrence button pressed", log: log, type: .debug)
            
            let selectionViewController = segue.destination as! ActivitySelectionViewController
            selectionViewController.activityStore = activityStore
            selectionViewController.delegate = self
        case "addNewActivityShortcut":
            os_log("Add Activity shortcut pressed", log: log, type: .debug)

            let detailViewController = segue.destination as! ActivityDetailViewController
            detailViewController.activityStore = activityStore
        default:
            preconditionFailure("Unexpected segue identifier: \(String(describing: segue.identifier))")
        }
    }
}

// MARK: UITableViewController methods
extension DailyActivitiesViewController {
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section == 0 else {
            return nil
        }
        
        return "Activities"
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 65
        case 1:
            return 32
        default:
            preconditionFailure("Unexpected section: \(indexPath.section)")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return currentActivities.count
        case 1:
            return 1
        default:
            preconditionFailure("Unexpected section: \(section)")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return tableView.dequeueReusableCell(withIdentifier: "DailyActivitiesViewCell", for: indexPath)
        case 1:
            return tableView.dequeueReusableCell(withIdentifier: "AddOccurrenceCell", for: indexPath)
        default:
            preconditionFailure("Unexpected section: \(indexPath.section)")
        }
    }
    
    private func didSelectActivityRowAt(indexPath: IndexPath) {
        let activity = self.activity(for: indexPath)
        
        if completedActivities.contains(activity) {
            setCompletionStatus(forActivityAt: indexPath, status: .notCompleted)
        } else {
            setCompletionStatus(forActivityAt: indexPath, status: .completed)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        configureTitle()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            didSelectActivityRowAt(indexPath: indexPath)
        case 1:
            print("Add Activity occurrence")
        default:
            preconditionFailure("Unexpected section: \(indexPath.section)")
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        precondition(indexPath.section == 0, "Editing should only be enabled for Activity section")
        
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
            load(for: dateDayBefore)
        case [.right]:
            guard !displayedDateIsToday else {
                return
            }
            os_log("Right edge pan recognized", log: log, type: .debug)
            load(for: dateDayAfter)
        default:
            preconditionFailure("Unrecognized edge pan gesture for edges: \(recognizer.edges)")
        }
    }
    
    func doubleDoubleTapped() {
        os_log("Double-double tap recognized", log: log, type: .debug)
        load(for: Date())
    }
}

extension DailyActivitiesViewController: ActivityOccurrenceHandler {
    func addActivityOccurrence(activity: Activity) {
        completionHistory.registerCompletion(for: activity, on: displayedDate, withStatus: .notCompleted)
    }
}
