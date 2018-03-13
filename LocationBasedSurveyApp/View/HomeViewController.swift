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
 
        // rounds the edges of buttons
        jsonButton.layer.cornerRadius = 4
        notificationButton.layer.cornerRadius = 4
        
    }
    
    //MARK: Actions
    @IBAction func jsonButton(_ sender: UIButton) {

        guard let url = URL(string: "http://sdp-2017-survey.cse.uconn.edu/test") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            
            do {
                let jsonData = try JSONDecoder().decode(Response.self, from: data)
                
                let alertController = UIAlertController(
                    title: "JSON Request",
                    message: jsonData.response,
                    preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(
                    title: "Dismiss",
                    style: .default,
                    handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            } catch let jsonError {
                print(jsonError)
            }
        }
        
        task.resume()
    }
    
    @IBAction func notificationButton(_ sender: UIButton) {
        SurveyHandler.shared.sendNotification(notificationTitle: "You pushed the button!", notificationBody: "Good work!")
    }
    
}
