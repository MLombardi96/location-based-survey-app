//
//  HomeViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Mitchell Lombardi on 4/26/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit
import UserNotifications
import CoreData

class HomeViewController: UITableViewController {
    
    @IBOutlet weak var currentEmailAddress: UILabel!
    @IBOutlet weak var currentAvailableSurveys: UILabel!
    @IBOutlet weak var currentCompletedSurveys: UILabel!
    
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        currentEmailAddress.text = UserDefaults.standard.string(forKey: "userEmail")
        getSurveyCount()
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert,.sound,.badge],
            completionHandler: { (granted,error) in}
        )
    }
    
    override func viewDidAppear(_ animated: Bool) { getSurveyCount() }
    
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        let separatorTop = UIView.init(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 3))
        separatorTop.backgroundColor = UIColor.lightGray
        cell.contentView.addSubview(separatorTop)
        
        let separatorRight = UIView.init(frame: CGRect(x: view.frame.size.width - 3, y: 0, width: 3, height: view.frame.size.height))
        separatorRight.backgroundColor = UIColor.lightGray
        cell.contentView.addSubview(separatorRight)
        
        let separatorLeft = UIView.init(frame: CGRect(x: 0, y: 0, width: 3, height: cell.frame.size.height))
        separatorLeft.backgroundColor = UIColor.lightGray
        cell.contentView.addSubview(separatorLeft)
        
        let tableRow = tableView.numberOfRows(inSection: indexPath.section)
        if indexPath.row == (tableRow - 1) {
            let separatorBottom = UIView.init(frame: CGRect(x: 0, y: cell.frame.size.height - 3, width: view.frame.size.width, height: 3))
            separatorBottom.backgroundColor = UIColor.lightGray
            cell.contentView.addSubview(separatorBottom)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = UIColor.white
            view.tintColor = UIColor.darkGray
        }
    }
}
