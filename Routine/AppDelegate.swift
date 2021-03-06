//
//  AppDelegate.swift
//  Routine
//
//  Created by Nick Holt on 5/3/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let lastActiveDefaultsKey = "lastActive"
    
    var activityStore: ActivityStore!
    var completionStore: CompletionStore!
    var completionHistory: CompletionHistory!
    
    private func configureGlobals() {
        configureActivityStore()
        configureCompletionStore()
        configureCompletionHistory()
    }
    
    private func configureActivityStore() {
        activityStore = ActivityStore(with: persistentContainer)
    }
    
    private func configureCompletionStore() {
        completionStore = CompletionStore(with: persistentContainer)
        try? completionStore.purgeDanglingCompletions()
    }
    
    private func configureCompletionHistory() {
        completionHistory = CompletionHistory()
        completionHistory.activityStore = activityStore
        completionHistory.completionStore = completionStore
    }
    
    private func populateMissingCompletionData() {
        if let lastTerminated = RoutineDefaults.getLastActive() {
            completionHistory.scrubCompletions(startingFrom: lastTerminated, endingOn: Date())
        }
    }
    
    private func configureRootViewController() {
        let routineTabBarController = window!.rootViewController as! RoutineTabBarController
        routineTabBarController.activityStore = activityStore
        routineTabBarController.completionStore = completionStore
        routineTabBarController.completionHistory = completionHistory
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        configureGlobals()
        
        populateMissingCompletionData()
        
        configureRootViewController()
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveContext), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil )
        
        registerDailyReminder()
        
        return true
    }
    
    func registerDailyReminder() {
        requestNotificationAuthorization()
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Reminder"
        content.body = "Have you completed today's activities?"
        
        var dateInfo = DateComponents()
        dateInfo.hour = 22
        dateInfo.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: true)
        
        let request = UNNotificationRequest(identifier: "DailyReminder", content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge]) { (granted, error) in
            if !granted {
                print("User did not allow for notifications")
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        RoutineDefaults.recordLastActive()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Routine")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

