//
//  UIViewController.swift
//  Routine
//
//  Created by Nick Holt on 5/29/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit

extension UIViewController {
    // DEBUG ONLY
    func presentAlert(withError error: Error) {
        let title = "ERROR ENCOUNTERED! PLEASE SEND NICK A SCREENSHOT"
        let message = "\(error)\n\(error.localizedDescription)"
    
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "Okay", style: .cancel)
        ac.addAction(okayAction)
        
        present(ac, animated: true)
    }
}
