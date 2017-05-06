//
//  DailyActivitiesViewCell.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

class DailyActivitiesViewCell: UITableViewCell {
    @IBOutlet var activityTitle: UILabel!
    @IBOutlet var currentStreak: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        activityTitle.adjustsFontForContentSizeCategory = true
        currentStreak.adjustsFontForContentSizeCategory = true
    }
}
