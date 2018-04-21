//
//  ViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Mitchell Lombardi on 10/12/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit
import UserNotifications
import Foundation

class HomeViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var currentEmailAddress: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentEmailAddress.text = UserDefaults.standard.string(forKey: "userEmail")
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert,.sound,.badge],
            completionHandler: { (granted,error) in}
        )

    }
    
}
