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
import SwiftyJSON
import CoreData

//TODO: when questions are available manage a 'short description' for tableView

/****
 * Handles parsing json files for survey data, creating surveys, creating geofences, and
 * displaying notifications.
 ****/
class SurveyHandler: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    static let shared: SurveyHandler = SurveyHandler()
    let locationManager: CLLocationManager
    let maxGeoFences = 20
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override public init() {
        // To use user defaults
        //UserDefaults.standard.register(defaults: [String : Any]())
        
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
    
    // MARK: Server Methods
    func requestSurveys() {
        // Endpoint: http://sdp-2017-survey.cse.uconn.edu/get_surveys
        // POST with JSON: { lat: <lat>, lng: <lng>, email: <email> }
        // Need 'Content-Type: application/json' in Header of POST request
        
        let userLatitude = Double((locationManager.location?.coordinate.latitude)!)
        let userLongitude = Double((locationManager.location?.coordinate.longitude)!)
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else {
            print("User email could not be pulled from settings bundle.")
            return
        }
        
        struct Request: Codable {
            let lat: String
            let lng: String
            let email: String
        }
        
        let request = Request(lat: String(userLatitude), lng: String(userLongitude), email: userEmail)
        let encodedRequest = try? JSONEncoder().encode(request)
        
        let url = URL(string: "http://sdp-2017-survey.cse.uconn.edu/get_surveys")
        var httpRequest = URLRequest(url: url!)
        httpRequest.httpMethod = "POST"
        httpRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.httpBody = encodedRequest
        
        let task = URLSession.shared.dataTask(with: httpRequest) { data, response, error in
            if error != nil {
                print("There was an error sending a POST request to the server. Error: \(String(describing: error))")
            }
            
            var newSurvey = [NewSurvey]()
            
            if let jsonData = data {
                // Create Fences
                let jsonFile = JSON(jsonData)

                let arrayFences = jsonFile["regions"].arrayValue
                for region in arrayFences {
                    let fenceID = region["id"].stringValue
                    let latitude = Double(String(format: "%.6f", region["center"]["lat"].doubleValue))!
                    let longitude = Double(String(format: "%.6f", region["center"]["lng"].doubleValue))!
                    let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let fence = CLCircularRegion(center: center, radius: region["radius"].doubleValue, identifier: fenceID)
                    self.locationManager.startMonitoring(for: fence)
                    
                    // Create Surveys
                    // Should make an array of fence ids so surveys will geofence properly
                    let surveyArray = region["surveys"].arrayValue
                    for survey in surveyArray {
                        let surveyID = survey["id"].stringValue
                        if newSurvey.isEmpty || !newSurvey.contains(where: {$0.surveyID == surveyID}) {
                            newSurvey.append(NewSurvey(
                                fenceID: fenceID,
                                surveyID: surveyID,
                                name: survey["name"].stringValue,
                                fenceName: region["name"].stringValue,
                                latitude: latitude,
                                longitude: longitude,
                                radius: region["radius"].doubleValue,
                                url: survey["URL"].stringValue,
                                isSelected: self.testContentsOfRegion(fence)
                            ))
                        }
                    }
                }
                self.updateDatabase(with: newSurvey)
            }
        }
        task.resume()
    }
    
    func surveyCompleted(with identifier: String) -> Bool {
        // Endpoint: http://sdp-2017-survey.cse.uconn.edu/complete_survey
        // POST with JSON: {survey:<surveyID>, email:<email>}
        
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else {
            print("User email could not be pulled from settings bundle.")
            return false
        }
        
        struct Request: Codable {
            let surveyID: String
            let email: String
        }
        
        let request = Request(surveyID: identifier, email: userEmail)
        let encodedRequest = try? JSONEncoder().encode(request)
        
        let url = URL(string: "http://sdp-2017-survey.cse.uconn.edu/complete_survey")
        var httpRequest = URLRequest(url: url!)
        httpRequest.httpMethod = "POST"
        httpRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.httpBody = encodedRequest
        
        let task = URLSession.shared.dataTask(with: httpRequest) { data, response, error in
            if error != nil {
                print("There was an error sending a POST request to the server. Error: \(String(describing: error))")
            }
            print("The survey was successfully sent to the server.")
        }
        task.resume()
        return true
    }
    
    // MARK: Database methods
    func updateDatabase(with newSurveys: [NewSurvey]) {
        container?.performBackgroundTask{ [weak self] context in
            for survey in newSurveys {
                _ = try? Survey.findOrCreateSurvey(matching: survey, in: context)
            }
            try? context.save()
            self?.printDatabaseStatistic()
        }
    }
    
    // prints how many surveys are currently in the database, ran on the main queue
    private func printDatabaseStatistic() {
        DispatchQueue.main.async {
            if let context = self.container?.viewContext {
                if let surveyCount = try? context.count(for: Survey.fetchRequest()) {
                    print("\(surveyCount) surveys")
                }
            }
        }
    }
}

// extension that contains all the CLLocaitonManager and UNUserNotification methods
extension SurveyHandler {

    func testContentsOfRegion(_ region: CLCircularRegion) -> Bool {
        let currentLat = locationManager.location?.coordinate.latitude
        let currentLong = locationManager.location?.coordinate.longitude
        let currentCoordinate = CLLocationCoordinate2D(latitude: currentLat!, longitude: currentLong!)
        
        if region.contains(currentCoordinate) {
            return true
        }
        
        return false
    }
    
    // Handles when the user walks into survey area, sends notification and adjusts table
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.sendNotification(notificationTitle: "A Survey is ready", notificationBody: "complete survey")
        if let context = self.container?.viewContext {
            context.perform {
                do {
                    let survey = try Survey.findSurveyWithFenceID(region.identifier, in: context)
                    for surveys in survey {
                        surveys.sectionName = "Ready to Complete"
                    }
                } catch {
                    print("Could not locate Survey in database.")
                }
                try? context.save()
            }
        }
    }
    
    // Handles when the user leaves the area, updates tables and will send surveys to server
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let context = self.container?.viewContext {
            context.perform {
                do {
                    let survey = try Survey.findSurveyWithFenceID(region.identifier, in: context)
                    for surveys in survey {
                        if surveys.isComplete {
                            
                            // send the completed survey to the server
                            if self.surveyCompleted(with: surveys.surveyID!) {
                                // remove fence
                                let center = CLLocationCoordinate2D(latitude: surveys.latitude, longitude: surveys.longitude)
                                let region = CLCircularRegion(center: center, radius: surveys.radius, identifier: surveys.fenceID!)
                                self.locationManager.stopMonitoring(for: region)
                                // remove from database.........changed with the history view
                                //_ = try Survey.removeFromDatabaseWith(survey: surveys.surveyID!, in: context)
                                //self.printDatabaseStatistic()
                                self.sendNotification(notificationTitle: "Survey sent!", notificationBody: "Your completed survey has been sent to the server.")
                            } else {
                                print("Failed to Post to server, resetting survey.")
                                surveys.isComplete = false
                            }
                        } else {
                            surveys.sectionName = "Surveys"
                        }
                    }
                } catch {
                    print("Could not location Survey with id \(region.identifier) in database.")
                }
                try? context.save()
            }
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
}


