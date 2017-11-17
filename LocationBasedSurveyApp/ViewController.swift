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

struct Response: Codable {
    let response: String
    let time: String
}

class ViewController: UIViewController, UNUserNotificationCenterDelegate {
    
    var isGrantedNotificationAccess:Bool = false
    var responses:[Response]?
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
    
    @IBAction func jsonButton(_ sender: Any) {
        guard let url = URL(string: "http://sdp-2017-survey.cse.uconn.edu/test") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            
            do {
                let jsonData = try JSONDecoder().decode(Response.self, from: data)
                
                let alertController = UIAlertController(title: "JSON Request", message: jsonData.response, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            } catch let jsonError {
                print(jsonError)
            }
        }
        
        task.resume()
    }
    
    //MARK: Actions
    @IBAction func notificationButton(_ sender: UIButton) {
        if isGrantedNotificationAccess{
            let content = UNMutableNotificationContent()
            content.title = "Location Based Survey App"
            content.body = "Notification Test Succeeded!"
            
            // Gives time to exit the app, notification will not appear if app is open
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: 5.0,
                repeats: false)
            
            //Set the request for the notification from the above
            let request = UNNotificationRequest(
                identifier: "button.test",
                content: content,
                trigger: trigger
            )
            
            //Add the notification to the currnet notification center
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}
