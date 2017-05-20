//
//  Completion+CoreDataClass.swift
//  Routine
//
//  Created by Nick Holt on 5/14/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation
import CoreData

@objc(Completion)
public class Completion: NSManagedObject {

    public enum Status: Int {
        case completed
        case notCompleted
        case excused
    }
    
    public let dateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        
        return dateFormatter
    }()
    
    public var status: Status {
        set {
            self.willChangeValue(forKey: "status")
            self.setPrimitiveValue(newValue.rawValue, forKey: "status")
            self.didChangeValue(forKey: "status")
        }
        get {
            self.willAccessValue(forKey: "status")
            guard let rawValue = self.primitiveValue(forKey: "status") else {
                return .notCompleted
            }
            self.didAccessValue(forKey: "status")
            
            return Status(rawValue: rawValue as! Int)!
        }
    }
    
    override public var description: String {
        let activityTitle = activity?.title ?? "???"
        
        let dateString: String
        if date != nil {
            dateString = dateFormatter.string(from: date!)
        } else {
            dateString = "??/??"
        }
        
        return "Completion<\(activityTitle), \(dateString), \(status)>"
    }
}
