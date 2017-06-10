//
//  CompletionHistoryTests.swift
//  Routine
//
//  Created by Nick Holt on 6/10/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import XCTest

@testable import Routine

class CompletionHistoryTests: RoutineTestCase {
    
    var completionHistory: CompletionHistory!
    
    var today: Date {
        return Date()
    }
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: today)!
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: today)!
    }
    
    override func setUp() {
        super.setUp()
        
        completionHistory = CompletionHistory()
        completionHistory.activityStore = activityStore
        completionHistory.completionStore = completionStore
    }
    
    func testRegisterSingleCompletionForSingleActivity() {
        let activity = activityStore.getNewEntity()
        
        let completionStatus = Completion.Status.completed
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: completionStatus)
        
        let completion = completionHistory.getCompletion(for: activity, on: today)
        
        XCTAssertNotNil(completion, "Completion could not be retrieved")
        XCTAssertEqual(completion?.status, completionStatus, "Completion status not properly set")
    }
    
    func testRegisterMultipleCompletionsForSingleActivity() {
        let activity = activityStore.getNewEntity()
        
        let expectedCompletionStatus = Completion.Status.excused
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: .completed)
        completionHistory.registerCompletion(for: activity, on: today, withStatus: expectedCompletionStatus)
        
        let completion = completionHistory.getCompletion(for: activity, on: today)
        
        XCTAssertNotNil(completion, "Completion could not be retrieved")
        XCTAssertEqual(completion!.status, expectedCompletionStatus, "Completion status not properly set")
    }
    
    func testRegisterCompletionsForMultipleActivitiesOnDifferentDays() {
        let activity0 = activityStore.getNewEntity()
        let activity1 = activityStore.getNewEntity()

        let completionStatus0 = Completion.Status.completed
        let completionStatus1 = Completion.Status.excused
        
        completionHistory.registerCompletion(for: activity0, on: today, withStatus: completionStatus0)
        completionHistory.registerCompletion(for: activity1, on: yesterday, withStatus: completionStatus1)
        
        let completion0 = completionHistory.getCompletion(for: activity0, on: today)
        
        XCTAssertNotNil(completion0, "Completion for first Activity could not be retrieved")
        XCTAssertEqual(
            completion0?.status,
            completionStatus0,
            "Completion status for first Activity not properly set"
        )
        XCTAssertNil(
            completionHistory.getCompletion(for: activity0, on: yesterday),
            "Completion was registered on incorrect day for first Activity"
        )

        let completion1 = completionHistory.getCompletion(for: activity1, on: yesterday)
        
        XCTAssertNotNil(completion1, "Completion for second Activity could not be retrieved")
        XCTAssertEqual(
            completion1?.status,
            completionStatus1,
            "Completion status for second Activity not properly set"
        )
        XCTAssertNil(
            completionHistory.getCompletion(for: activity1, on: today),
            "Completion was registered on incorrect day for second Activity"
        )
    }
    
    func testCanRegisterCompletionForActivityInFuture() {
        let activity = activityStore.getNewEntity()
        
        let completionStatus = Completion.Status.completed
        
        completionHistory.registerCompletion(for: activity, on: tomorrow, withStatus: completionStatus)
        
        let completion = completionHistory.getCompletion(for: activity, on: tomorrow)
        
        XCTAssertNotEqual(completion, nil, "Completion could not be retrieved")
        XCTAssertEqual(completion?.status, completionStatus, "Completion status not properly set")
    }
}
