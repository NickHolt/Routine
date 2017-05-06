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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure tabbed view controllers
        let dailyActivitiesNavigationController = self.viewControllers?.first! as! UINavigationController
        let dailyActivitiesViewController = dailyActivitiesNavigationController.topViewController as! DailyActivitiesViewController
        dailyActivitiesViewController.activityStore = activityStore
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
