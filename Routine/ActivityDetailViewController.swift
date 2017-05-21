//
//  ActivityDetailViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

class ActivityDetailViewController: UIViewController, UITextFieldDelegate {
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
        
        // Populate activity data
        guard let currentActivity = activity else {
            return
        }

        activityTitle.text = currentActivity.title
        
        for day in currentActivity.daysOfWeek {
            buttonMap[day]!.isSelected = true
        }
        
        activityTitle.becomeFirstResponder()
        
        if let startDate = activity?.startDate {
            datePicker.date = startDate
        }
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
        do {
            try activityStore.persistToDisk()
        } catch {
            print("Warning: could not persist ActivityStore to disk!")
        }
        
        // Dismiss myself
        navigationController?.popViewController(animated: true)
    }
}
