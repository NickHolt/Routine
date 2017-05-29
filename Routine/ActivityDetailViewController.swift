//
//  ActivityDetailViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit
import os.log

class ActivityDetailViewController: UIViewController, UITextFieldDelegate {
    
    let log = OSLog(subsystem: "com.redox.Routine", category: "ActivityDetailViewController")

    @IBOutlet var activityTitle: UITextField!
    
    @IBOutlet var saveButton: UIBarButtonItem!
    
    @IBOutlet var mondayButton: DayOfWeekButton!
    @IBOutlet var tuesdayButton: DayOfWeekButton!
    @IBOutlet var wednesdayButton: DayOfWeekButton!
    @IBOutlet var thursdayButton: DayOfWeekButton!
    @IBOutlet var fridayButton: DayOfWeekButton!
    @IBOutlet var saturdayButton: DayOfWeekButton!
    @IBOutlet var sundayButton: DayOfWeekButton!
    
    var buttonMap: [DayOfWeek:DayOfWeekButton]!
    
    @IBOutlet var datePicker: UIDatePicker!
    
    @IBOutlet var archiveButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    
    var activity: Activity?
    var activityStore: ActivityStore!
    var completionHistory: CompletionHistory!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        buttonMap = [DayOfWeek:DayOfWeekButton]()
        buttonMap[.Monday] = mondayButton
        buttonMap[.Tuesday] = tuesdayButton
        buttonMap[.Wednesday] = wednesdayButton
        buttonMap[.Thursday] = thursdayButton
        buttonMap[.Friday] = fridayButton
        buttonMap[.Saturday] = saturdayButton
        buttonMap[.Sunday] = sundayButton
        
        // Populate activity data
        guard let currentActivity = activity else {
            os_log("Displaying detail view for new activity", log: log, type: .info)
            
            activityTitle.becomeFirstResponder()

            return
        }
        
        os_log("Displaying details for Activity: %@", log: log, type: .info, currentActivity)

        activityTitle.text = currentActivity.title
        
        for day in currentActivity.daysOfWeek {
            buttonMap[day]!.isSelected = true
        }
        
        if let startDate = activity?.startDate {
            datePicker.date = startDate
        }
        
        deleteButton.isHidden = false
        
        // Disable elements if archived
        guard !currentActivity.isActive else {
            archiveButton.isHidden = false
            return
        }
        
        activityTitle.isEnabled = false
        
        for (_, button) in buttonMap {
            button.isEnabled = false
        }
        
        datePicker.isEnabled = false
        
        navigationItem.rightBarButtonItem = nil
    }
    
    @IBAction func toggleDayButton(_ sender: DayOfWeekButton) {
        sender.isSelected = !sender.isSelected
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @IBAction func saveActivity(_ sender: UIBarButtonItem) {
        os_log("Save button pressed", log: log, type: .debug)
        
        if activity == nil {
            activity = activityStore.getEntity()
        }
        let activityToUpdate = activity!
        
        if let newActivityTitle = activityTitle.text, !newActivityTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            activityToUpdate.title = newActivityTitle
        }
        
        var newDaysOfWeek = [DayOfWeek]()
        for (day, button) in buttonMap {
            if button.isSelected {
                newDaysOfWeek.append(day)
            }
        }
        activityToUpdate.daysOfWeek = newDaysOfWeek
        
        activityToUpdate.startDate = datePicker.date
        
        // Save to disk
        // MARK: TODO<nickholt> handle CoreDate failure
        try! activityStore.persistToDisk()
        
        // Dismiss myself
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func archiveActivity(_ sender: UIButton) {
        guard let activityToArchive = activity else {
            return
        }
        
        // Display confirmation alert
        let title = "Archive \(String(describing: activityToArchive.title ?? ""))?"
        let message = "Archiving an activity will remove all future occurrences, and cannot be undone. Are you sure you want to permanently archive this Activity?"
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ac.addAction(cancelAction)
        
        let archiveAction = UIAlertAction(title: "Archive", style: .destructive) { (action) in
            os_log("User indicated archive for Activity: %@", log: self.log, type: .debug, activityToArchive)
            
            try? self.activityStore.archive(activity: activityToArchive)
            
            // Dismiss myself
            self.navigationController?.popViewController(animated: true)
        }
        ac.addAction(archiveAction)
        
        present(ac, animated: true, completion: nil)
    }
    
    @IBAction func deleteActivity(_ sender: UIButton) {
        guard let activityToDelete = activity else {
            return
        }
        
        // Display confirmation alert
        let title = "Delete \(String(describing: activityToDelete.title ?? ""))?"
        let message = "This will permanently remove this activity's data, including all past completions. Are you sure you want to delete this Activity?"
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ac.addAction(cancelAction)
        
        let archiveAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            os_log("User indicated deletion for Activity: %@", log: self.log, type: .debug, activityToDelete)
            
            try? self.activityStore.delete(activity: activityToDelete)
            
            // Dismiss myself
            self.navigationController?.popViewController(animated: true)
        }
        ac.addAction(archiveAction)
        
        present(ac, animated: true, completion: nil)
    }
}
