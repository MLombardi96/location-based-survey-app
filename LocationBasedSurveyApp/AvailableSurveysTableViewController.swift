//
//  AvailableSurveysTableViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/22/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

class AvailableSurveysTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    //MARK: Properties
    let locationManager = CLLocationManager()
    let section = ["Surveys To Complete", "Available Surveys"]
    var availableSurveys = [Survey]() // Empty array of available survey objects
    var surveysToComplete = [Survey]()
    
    //MARK: Private Methods
    private func loadSampleSurveys() {
        guard let survey1 = Survey(name: "Bookstore", shortDescription: "What is the bookstore like?", latitude: 41.805179, longitude: -72.253386, radius: 50)
            else {
                fatalError("Unable to initialize survey1")
        }
        
        guard let survey2 = Survey(name: "Home", shortDescription: "Is home really that good?", latitude: 41.908072, longitude: -72.371841, radius: 50)
            else {
                fatalError("Unable to initalize survey2")
        }
        availableSurveys = [survey1, survey2]
    }
    
    private func addGeofences() {
        for survey in availableSurveys {
            let center = CLLocationCoordinate2D(latitude: survey.latitude, longitude: survey.longitude)
            let region = CLCircularRegion(center: center, radius: survey.radius, identifier: survey.name)
            locationManager.startMonitoring(for: region)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
        // load sample data
        loadSampleSurveys()
        addGeofences()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table View Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.section.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.section[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.availableSurveys.count - self.surveysToComplete.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "AvailableSurveysTableViewCell"
        
        // As the user scrolls the cells are reused with the ones off screen
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AvailableSurveysTableViewCell else {
            fatalError("The dequeue cell is not an instance of AvailableSurveysTableViewCell")
        }
        
        // double check this code, needs more with optionals
        let survey = availableSurveys[indexPath.row] // fetches the correct survey from the array
        cell.surveyTitle.text = survey.name
        cell.surveyDemoDescription.text = survey.name

        return cell
    }
    
    // MARK: Location Manager Methods
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {

        sendNotification(notificationTitle: "Welcome to \(region.identifier)!", notificationBody: "You made it.")
        
        if availableSurveys.count != 0 {
            var indexToRemove = 0
            for i in 0..<availableSurveys.count {
                if region.identifier == availableSurveys[i].name {
                    indexToRemove = i
                    availableSurveys[i].isSelected = true
                    surveysToComplete += [availableSurveys[i]]
                }
            }
            availableSurveys.remove(at: indexToRemove)
        }
        print("Available Surveys: \(availableSurveys.count)")
        print("Surveys to complete: \(surveysToComplete.count)")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if surveysToComplete.count != 0 {
            var indexToRemove = 0
            for i in 0..<surveysToComplete.count {
                if region.identifier == surveysToComplete[i].name {
                    indexToRemove = i
                    surveysToComplete[i].isSelected = true
                    availableSurveys += [surveysToComplete[i]]
                }
            }
            surveysToComplete.remove(at: indexToRemove)
        }
        print("Available Surveys: \(availableSurveys.count)")
        print("Surveys to complete: \(surveysToComplete.count)")
    }
    
    func sendNotification(notificationTitle title: String, notificationBody body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default()
        
        // Gives time to exit the app, notification will not appear if app is open
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 0.1,
            repeats: false)
        
        //Set the request for the notification from the above
        let request = UNNotificationRequest(
            identifier: "button.survey",
            content: content,
            trigger: trigger
        )
        
        //Add the notification to the currnet notification center
        UNUserNotificationCenter.current().add(request,withCompletionHandler: nil)
    }

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // grabs the current selected available survey from array
        // passes it to the GoogleMapsViewController
        let survey = availableSurveys[(tableView.indexPathForSelectedRow?.row)!]
        if let destinationViewController = segue.destination as? GoogleMapsViewController {
            destinationViewController.survey = survey
        }
    }
}
