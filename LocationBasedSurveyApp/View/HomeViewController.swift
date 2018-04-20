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
    @IBOutlet weak var jsonButton: UIButton!
    @IBOutlet weak var notificationButton: UIButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert,.sound,.badge],
            completionHandler: { (granted,error) in}
        )
 
        // Rounds the edges of buttons
        jsonButton.layer.cornerRadius = 4
        notificationButton.layer.cornerRadius = 4
    }
    
    //MARK: Actions
    @IBAction func jsonButton(_ sender: UIButton) {
    }
    
    @IBAction func notificationButton(_ sender: UIButton) {
    }
    
}
