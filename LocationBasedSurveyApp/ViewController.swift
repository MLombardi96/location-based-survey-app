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

class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    
    var isGrantedNotificationAccess:Bool = false
    
    //MARK: Properties

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prompts user to allow notifications when it first loads
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert,.sound,.badge],
            completionHandler: { (granted,error) in
                self.isGrantedNotificationAccess = granted
            }
        )
        
        // for remote access when we get that far
        //application.registerForRemoteNotifications()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Actions
    @IBAction func notificationButton(_ sender: UIButton) {
        if isGrantedNotificationAccess{
            let content = UNMutableNotificationContent()
            content.title = "Button Notification Test"
            content.subtitle = "Location Based Survey App"
            content.body = "Notification Test Succeeded!"
            
            // Gives time to exit the app, notification will not appear if app is open
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 10.0,
                repeats: false)
            
            //Set the request for the notification from the above
            let request = UNNotificationRequest(
                identifier: "button.test",
                content: content,
                trigger: trigger
            )
            
            //Add the notification to the currnet notification center
            UNUserNotificationCenter.current().add(
                request, withCompletionHandler: nil)
        }
    }
    
    @IBAction func jsonButton(_ sender: Any) {
            
    }
}
