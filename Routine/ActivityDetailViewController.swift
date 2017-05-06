//
//  ActivityDetailViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

class ActivityDetailViewController: UIViewController {
    @IBOutlet var activityTitle: UITextField!
    
    @IBOutlet var mondayButton: UIButton!
    @IBOutlet var tuesdayButton: UIButton!
    @IBOutlet var wednesdayButton: UIButton!
    @IBOutlet var thursdayButton: UIButton!
    @IBOutlet var fridayButton: UIButton!
    @IBOutlet var saturdayButton: UIButton!
    @IBOutlet var sundayButton: UIButton!
    
    var activity: Activity!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Populate activity data
        activityTitle.text = activity.title
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Save activity data
        if let newActivityTitle = activityTitle.text {
            activity.title = newActivityTitle
        }
    }
    
    @IBAction func toggleDayButton(_ sender: DayOfWeekButton) {
        sender.isSelected = !sender.isSelected
    }
}
