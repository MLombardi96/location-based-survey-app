//
//  SurveyHandler.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/28/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import Foundation
import CoreLocation
import UserNotifications

//TODO: add a maximum of 20 and cache the rest (Database?)
// TODO: save JSON question file in the survey parse if user enters area
//TODO: when questions are available manage a 'short description' for tableView

// Structure used to contain json elements, created to match Colin's sample file
struct Root: Decodable {
    struct Survey: Decodable {
        let ID: String
        let Name: String
        let LatLng: [Double]
        //let Description: String
        let Radius: Double
    }
    var Surveys: [Survey]
}

/****
 * Handles parsing json files for survey data, creating surveys, creating geofences, and
 * displaying notifications. 
 ****/
class SurveyHandler: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    static let shared: SurveyHandler = SurveyHandler()
    
    let locationManager: CLLocationManager
    let maxGeoFences = 19
    var surveysReadyToComplete = [Survey]()
    var surveysWithinArea = [Survey]()
    var surveyHistory = [Survey]()

    override init() {
        // Location Manager initialization
        self.locationManager = CLLocationManager()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        super.init()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            self.locationManager.startUpdatingLocation()
            self.locationManager.delegate = self
        }
    }
    
    //MARK: Private Methods
    /****
     * Parses through json file creating Surveys with the data. Also
     * creates geofences for each Survey.
     ****/
    func setupSurveyFences() {
        User.shared.resetGeofence()
        // Currently gets json file locally
        let url = Bundle.main.url(forResource: "Surveys", withExtension: "json")
        do {
            let data = try Data.init(contentsOf: url!, options: .alwaysMapped)
            var root  = try JSONDecoder().decode(Root.self, from: data)
            
            // loop through parsing the survey info out of json file creating Surveys
            for i in 0..<root.Surveys.count {
                if surveysReadyToComplete.contains(where: {$0.id == root.Surveys[i].ID}) || surveysWithinArea.contains(where: {$0.id == root.Surveys[i].ID}){
                    continue
                }
                guard let newSurvey = Survey(&root.Surveys[i]) else {return}
                
                // Add GeoFence for new Surveys
                createGeofence(with: newSurvey.region)
                
                if User.shared.latitude == newSurvey.latitude && User.shared.longitude == newSurvey.longitude {
                    newSurvey.isSelected = true
                    surveysReadyToComplete.append(newSurvey)
                } else {
                    surveysWithinArea.append(newSurvey)
                }

            }
        } catch let jsonError {
            print(jsonError.localizedDescription)
        }
    }
    
    // populates the history table
    func getSurveyHistory() -> [Survey] {
        if surveyHistory.isEmpty {
            return [Survey()]
        }
        return surveyHistory
    }
    
    func createGeofence(with region: CLCircularRegion) {
        locationManager.startMonitoring(for: region)
    }
    
    // called from SurveyQuestionViewController when the survey has been completed
    func userHasCompleted(_ survey: Survey) {
        survey.isComplete = true
        guard let surveyID = survey.id else {return}
        DBManager.shared.insertSurveyIntoTable(identifier: surveyID, name: survey.name, latitude: survey.latitude, longitude: survey.longitude)
        let index = surveysReadyToComplete.index(where: {$0.id == surveyID})
        if index != nil {
            surveyHistory.append(surveysReadyToComplete.remove(at: index!))
            locationManager.stopMonitoring(for: survey.region)
        }
    }
    
    // Made public so the notification button on the homepage will still operate
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
    
    //MARK: Location Manager Methods
    // Handles what happens when the user enters a geofenced region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // TODO: parse JSON file of questions to ready them for user
        
        if surveysWithinArea.contains(where: {$0.id == region.identifier}) && !surveysWithinArea.isEmpty {
            let index = surveysWithinArea.index(where: {$0.id == region.identifier})
            sendNotification(notificationTitle: "Survey Available", notificationBody: "The \(surveysWithinArea[index!].name) survey is available to complete.")
            if index != nil {
                surveysWithinArea[index!].isSelected = true
                surveysReadyToComplete.append(surveysWithinArea.remove(at: index!))
            }
        }
    }
    
    // Handles what happens when the user exits a geofenced region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // TODO: check if aurvey has been completed, if so send to server
        
        if surveysReadyToComplete.contains(where: {$0.id == region.identifier}) && !surveysReadyToComplete.isEmpty {
            let index = surveysReadyToComplete.index(where: {$0.id == region.identifier})
            if index != nil {
                surveysReadyToComplete[index!].isSelected = false
                surveysWithinArea.append(surveysReadyToComplete.remove(at: index!))
            }
        } else if region.identifier == "User" {
            locationManager.stopMonitoring(for: region)
            // request from server
            sendNotification(notificationTitle: "You left?", notificationBody: "Why you leave?")
            User.shared.resetGeofence()
        }
    }
}
