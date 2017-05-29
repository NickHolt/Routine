//
//  RoutineTabBarController.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

class RoutineTabBarController: UITabBarController {
    
    var activityStore: ActivityStore!
    var completionStore: CompletionStore!
    var completionHistory: CompletionHistory!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure tabbed view controllers
        let dailyActivitiesNavigationController = self.viewControllers?.first! as! UINavigationController
        
        let dailyActivitiesViewController = dailyActivitiesNavigationController.topViewController as! DailyActivitiesViewController
        dailyActivitiesViewController.activityStore = activityStore
        dailyActivitiesViewController.completionStore = completionStore
        dailyActivitiesViewController.completionHistory = completionHistory
        
        let activitiesNavigationController = self.viewControllers?[1] as! UINavigationController
        let activitiesViewController = activitiesNavigationController.topViewController as! ActivitiesViewController
        activitiesViewController.activityStore = activityStore
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
