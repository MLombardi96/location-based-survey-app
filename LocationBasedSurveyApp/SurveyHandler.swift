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
    
    private let locationManager: CLLocationManager
    var surveysReadyToComplete = [Survey]()
    var surveysWithinArea = [Survey]()
    
    var totalSurveys: Int {
        get {
            return surveysReadyToComplete.count + surveysWithinArea.count
        }
    }
    
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
        pullSurveysFromServer()
    }
    
    //MARK: Private Methods
    /****
     * Parses through json file creating Surveys with the data. Also
     * creates geofences for each Survey.
     ****/
    private func pullSurveysFromServer() {
        // Currently gets json file locally
        let url = Bundle.main.url(forResource: "Surveys", withExtension: "json")
        do {
            let data = try Data.init(contentsOf: url!, options: .alwaysMapped)
            var root  = try JSONDecoder().decode(Root.self, from: data)
            
            // loop through parsing the survey info out of json file creating Surveys
            for i in 0..<root.Surveys.count {

                if let userCoordinates = locationManager.location?.coordinate {
                    user.setUserCoordinates(coordinates: userCoordinates)
                    
                    if let newSurvey = Survey(&root.Surveys[i]) {
                        
                        // Add GeoFence for new Surveys
                        let center = CLLocationCoordinate2D(latitude: newSurvey.latitude, longitude: newSurvey.longitude)
                        
                        guard let identifier = newSurvey.id else {return}
                        let region = CLCircularRegion(center: center, radius: newSurvey.radius, identifier: identifier)
                        locationManager.startMonitoring(for: region)
                        
                        if user.latitude == newSurvey.latitude && user.longitude == newSurvey.longitude {
                            newSurvey.isSelected = true
                            surveysReadyToComplete.append(newSurvey)
                        } else {
                            surveysWithinArea.append(newSurvey)
                        }
                    }
                }
            }
        } catch let jsonError {
            print(jsonError)
        }
    }
    
    // default function until database is setup
    func loadSurveyHistory() -> [Survey] {
        // load survey history from database
        // if history is empty, load the empty survey
        return [Survey()]
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
        // TODO: parse JSON question file and 
        
        sendNotification(notificationTitle: "Welcome to \(region.identifier)!", notificationBody: "You made it.")
        if surveysWithinArea.contains(where: {$0.id == region.identifier}) && !surveysWithinArea.isEmpty {
            let index = surveysWithinArea.index(where: {$0.id == region.identifier})
            if index != nil {
                surveysWithinArea[index!].isSelected = true
                surveysReadyToComplete.append(surveysWithinArea.remove(at: index!))
            }
        }
    }
    
    // Handles what happens when the user exits a geofenced region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // TODO: if user exits their area, notify server
        
        if surveysReadyToComplete.contains(where: {$0.id == region.identifier}) && !surveysReadyToComplete.isEmpty {
            let index = surveysReadyToComplete.index(where: {$0.id == region.identifier})
            if index != nil {
                surveysReadyToComplete[index!].isSelected = false
                surveysWithinArea.append(surveysReadyToComplete.remove(at: index!))
            }
        }
    }
}
