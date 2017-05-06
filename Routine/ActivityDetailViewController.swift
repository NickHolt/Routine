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
}
