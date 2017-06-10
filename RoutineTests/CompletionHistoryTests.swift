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
    
    override func setUp() {
        super.setUp()
        
        completionHistory = CompletionHistory()
        completionHistory.activityStore = activityStore
        completionHistory.completionStore = completionStore
    }
}
