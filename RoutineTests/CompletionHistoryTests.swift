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
        
        XCTAssertNotNil(completion, "Completion could not be retrieved")
        XCTAssertEqual(completion?.status, completionStatus, "Completion status not properly set")
    }
    
    func testDeleteSingleCompletionForActivity() {
        let activity = activityStore.getNewEntity()
        
        let completionStatus = Completion.Status.completed
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: completionStatus)
        completionHistory.deleteCompletion(for: activity, on: today)
        
        let completion = completionHistory.getCompletion(for: activity, on: today)

        XCTAssertNil(completion, "Completion was not deleted")
    }
    
    func registerSeveralCompletions(for activity: Activity) {
        completionHistory.registerCompletion(for: activity, on: yesterday, withStatus: .notCompleted)
        completionHistory.registerCompletion(for: activity, on: today, withStatus: .excused)
        completionHistory.registerCompletion(for: activity, on: tomorrow, withStatus: .completed)
    }
    
    func testDeleteCompletionHistoryForSingleActivity() {
        let activity = activityStore.getNewEntity()
        
        registerSeveralCompletions(for: activity)

        try! completionHistory.deleteCompletionHistory(for: activity)
        
        XCTAssertNil(
            completionHistory.getCompletion(for: activity, on: yesterday),
            "Yesterday's Completion was not deleted"
        )
        XCTAssertNil(
            completionHistory.getCompletion(for: activity, on: today),
            "Today's Completion was not deleted"
        )
        XCTAssertNil(
            completionHistory.getCompletion(for: activity, on: tomorrow),
            "Tomorrow's Completion was not deleted"
        )
    }
    
    func testDeleteCompletionHistoryForMultipleActivities() {
        let activity0 = activityStore.getNewEntity()
        let activity1 = activityStore.getNewEntity()
        
        registerSeveralCompletions(for: activity0)
        registerSeveralCompletions(for: activity1)
        
        try! completionHistory.deleteCompletionHistory(for: activity0)
        XCTAssertNil(
            completionHistory.getCompletion(for: activity0, on: yesterday),
            "Yesterday's Completion was not deleted for first Activity"
        )
        XCTAssertNil(
            completionHistory.getCompletion(for: activity0, on: today),
            "Today's Completion was not deleted for first Activity"
        )
        XCTAssertNil(
            completionHistory.getCompletion(for: activity0, on: tomorrow),
            "Tomorrow's Completion was not deleted for first Activity"
        )
        
        XCTAssertNotNil(
            completionHistory.getCompletion(for: activity1, on: yesterday),
            "Yesterday's Completion was prematurely deleted for second Activity"
        )
        XCTAssertNotNil(
            completionHistory.getCompletion(for: activity1, on: today),
            "Today's Completion was prematurely deleted for second Activity"
        )
        XCTAssertNotNil(
            completionHistory.getCompletion(for: activity1, on: tomorrow),
            "Tomorrow's Completion was prematurely deleted for second Activity"
        )

        try! completionHistory.deleteCompletionHistory(for: activity1)
        XCTAssertNil(
            completionHistory.getCompletion(for: activity1, on: yesterday),
            "Yesterday's Completion was not deleted for second Activity"
        )
        XCTAssertNil(
            completionHistory.getCompletion(for: activity1, on: today),
            "Today's Completion was not deleted for second Activity"
        )
        XCTAssertNil(
            completionHistory.getCompletion(for: activity1, on: tomorrow),
            "Tomorrow's Completion was not deleted for second Activity"
        )
    }
    
    func testCompletionStreakForSingleActivityWithNoFallback() {
        let activity = activityStore.getNewEntity()
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: .completed)
        
        var streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today)
        XCTAssertEqual(streak, 1, "Streak for today's Completion was not registered")
        
        completionHistory.registerCompletion(for: activity, on: yesterday, withStatus: .completed)

        streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today)
        XCTAssertEqual(streak, 2, "Streak for yesterday's Completion was not registered")
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: .notCompleted)
        
        streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today)
        XCTAssertEqual(streak, 0, "Streak was not broken")
}
    
    func testCompletionStreakForSingleActivityWithFallback() {
        let activity = activityStore.getNewEntity()
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: .completed)
        
        var streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today)
        XCTAssertEqual(streak, 1, "Streak for today's Completion was not registered")
        
        completionHistory.registerCompletion(for: activity, on: yesterday, withStatus: .completed)
        
        streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today)
        XCTAssertEqual(streak, 2, "Streak for yesterday's Completion was not registered")
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: .notCompleted)
        
        streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today, withPreviousFallback: true)
        XCTAssertEqual(streak,  1, "Could not fall back to previous day's streak")
    }

    func testCompletionStreakForSingleActivityWithExcused() {
        let activity = activityStore.getNewEntity()
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: .completed)
        
        var streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today)
        XCTAssertEqual(streak, 1, "Streak for today's Completion was not registered")
        
        completionHistory.registerCompletion(for: activity, on: yesterday, withStatus: .completed)
        
        streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today)
        XCTAssertEqual(streak, 2, "Streak for yesterday's Completion was not registered")
        
        completionHistory.registerCompletion(for: activity, on: today, withStatus: .excused)
        
        streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: today)
        XCTAssertEqual(streak,  1, "Excused Completion broke streak")
        
        completionHistory.registerCompletion(for: activity, on: tomorrow, withStatus: .completed)

        streak = try! completionHistory.getCompletionStreak(for: activity, endingOn: tomorrow)
        XCTAssertEqual(streak,  2, "Excused Completion broke streak")
    }
    
    func testActivityScrubbing() {
        let activity = activityStore.getNewEntity()

        activity.startDate = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        activity.daysOfWeek = [
            .monday,
            .Wednesday,
            .Friday,
        ]
        
        completionHistory.scrubCompletions(for: activity, startingFrom: activity.startDate!, endingOn: today)
        let completions = completionStore.getAllCompletions(for: activity)
        
        XCTAssertEqual(completions.count, activity.daysOfWeek.count, "Completions over the last week not added")
    }
}
