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
import CoreData

class HomeViewController: UIViewController {
    
    //MARK: Properties
    @IBOutlet weak var currentEmailAddress: UILabel!
    @IBOutlet weak var currentAvailableSurveys: UILabel!
    @IBOutlet weak var currentCompletedSurveys: UILabel!
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentEmailAddress.text = UserDefaults.standard.string(forKey: "userEmail")
        getSurveyCount()
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert,.sound,.badge],
            completionHandler: { (granted,error) in}
        )
    }
    
    func getSurveyCount() {
        if let context = self.container?.viewContext {
            context.perform {
                do {
                    let availableSurveys = try Survey.getSurveysThat(are: false, in: context)
                    self.currentAvailableSurveys.text = String(availableSurveys.count)
                    let completedSurveys = try Survey.getSurveysThat(are: true, in: context)
                    self.currentCompletedSurveys.text = String(completedSurveys.count)
                } catch {
                    print("Could not get survey counts.")
                    self.currentAvailableSurveys.text = "0"
                    self.currentCompletedSurveys.text = "0"
                }
            }
        }
    }
    
}
