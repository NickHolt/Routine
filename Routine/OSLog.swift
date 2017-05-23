//
//  OSLog.swift
//  Routine
//
//  Created by Nick Holt on 5/23/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    var defaultDateFormatter: DateFormatter {
        get {
            var dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd"
            
            return dateFormatter
        }
    }
}
