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
    
    var activity: Activity?
    var activityStore: ActivityStore!
    
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
        
        activityTitle.becomeFirstResponder()
        
        // Populate activity data
        guard let currentActivity = activity else {
            os_log("Displaying detail view for new activity", log: log, type: .info)
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
        
        archiveButton.isHidden = false
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
            activity = activityStore.fetchNewActivity()
        }
        
        // Save activity data
        if let newActivityTitle = activityTitle.text, !newActivityTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            activity?.title = newActivityTitle
        }
        
        var newDaysOfWeek = [DayOfWeek]()
        for (day, button) in buttonMap {
            if button.isSelected {
                newDaysOfWeek.append(day)
            }
        }
        activity?.daysOfWeek = newDaysOfWeek
        
        activity?.startDate = datePicker.date
        
        // Save to disk
        try? activityStore.persistToDisk()
        
        // Dismiss myself
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func archiveActivity(_ sender: UIButton) {
        os_log("User indicated archive for Activity: %@", log: log, type: .debug, activity!)
        
        try? activityStore.archive(activity: activity!)

        // Dismiss myself
        navigationController?.popViewController(animated: true)
    }
}
