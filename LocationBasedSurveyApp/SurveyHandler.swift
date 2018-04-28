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

class SurveyHandler: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    static let shared: SurveyHandler = SurveyHandler()
    private let state: UIApplicationState = UIApplication.shared.applicationState
    private let locationManager: CLLocationManager
    private var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    private let maxGeoFences = 20
    
    // initializes the location manager
    override public init() {
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
        // removes all fences and everything in the database (except completed surveys)
        dumpMonitoredRegions()
        if let context = self.container?.viewContext {
            context.perform {
                do {
                    try Survey.removeEverythingFromDatabase(in: context)
                } catch { return }
            }
        }
        
        // local variables
        guard let currentCoordinate = locationManager.location?.coordinate else {
            print("Location manager could not determine current coordinates.")
            return
        }
        let userLatitude = Double(currentCoordinate.latitude)
        let userLongitude = Double(currentCoordinate.longitude)
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else {
            print("Error retrieving user's email address from bundle or value is left empty.")
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
                return
            }
            
            // Parse JSON file, can change to decoder once JSON format is fixed
            if let jsonData = data {
                let jsonFile = JSON(jsonData)
                let newSurveys = self.parseJSON(jsonFile, current: currentCoordinate)
                self.updateDatabase(with: newSurveys, current: currentCoordinate)
            }
        }
        task.resume()
    }
    
    // run when the survey has been completed
    private func surveyCompleted(with identifier: String) -> Bool {
        // Endpoint: http://sdp-2017-survey.cse.uconn.edu/complete_survey
        // POST with JSON: {survey:<surveyID>, email:<email>}
        
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail") else {
            print("User email could not be pulled from settings bundle or is empty.")
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
                return
            }
            if let jsonData = data {
                let jsonFile = JSON(jsonData)
                print(jsonFile.rawValue)  //empty?
            }
        }
        task.resume()
        return true
    }
    
    //MARK: JSON parsing
    func parseJSON(_ jsonFile: JSON, current coordinate: CLLocationCoordinate2D) -> [NewSurvey] {
        var newSurvey = [NewSurvey]()
        var newRegion = [NewFence]()
        
        let arrayFences = jsonFile["regions"].arrayValue
        for region in arrayFences {
            
            // Create new fence
            let newFence = NewFence(
                id: region["id"].stringValue,
                name: region["name"].stringValue,
                latitude: Double(String(format: "%.6f", region["center"]["lat"].doubleValue))!,
                longitude: Double(String(format: "%.6f", region["center"]["lng"].doubleValue))!,
                userLocation: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
                radius: region["radius"].doubleValue)
            
            
            // append fences
            let center = CLLocationCoordinate2D(latitude: newFence.latitude, longitude: newFence.longitude)
            let fence = CLCircularRegion(center: center, radius: newFence.radius, identifier: newFence.id)
            newRegion.append(newFence)
            
            // append newSurveys to be added to the database
            let surveyArray = region["surveys"].arrayValue
            for survey in surveyArray {
                let surveyID = survey["id"].stringValue
                if newSurvey.isEmpty || !newSurvey.contains(where: {$0.id == surveyID}) {
                    newSurvey.append(NewSurvey(
                        id: surveyID,
                        name: survey["name"].stringValue,
                        url: survey["URL"].stringValue,
                        isSelected: testContentsOfRegion(fence),
                        fences: [newFence]
                    ))
                } else if let index = newSurvey.index(where: {$0.id == surveyID}) {
                    if !newSurvey[index].isSelected {
                        newSurvey[index].isSelected = testContentsOfRegion(fence)
                    }
                    newSurvey[index].fences.append(newFence)
                }
            }
        }
        startMonitoringGeofences(with: &newRegion)
        return newSurvey
    }
    
    //MARK: Database methods
    private func updateDatabase(with newSurveys: [NewSurvey], current coordinates: CLLocationCoordinate2D) {
        var priority = 1
        let sortedSurveys = newSurveys.sorted{ return $0.fences[0].distance < $1.fences[0].distance }
        
        container?.performBackgroundTask{ [weak self] context in
            for survey in sortedSurveys {
                _ = try? Survey.findOrCreateSurvey(matching: survey, with: priority, in: context)
                priority = priority + 1
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
                    print("\(surveyCount) surveys") }
            }
        }
    }
}

// extension that contains all the CLLocaitonManager and UNUserNotification methods
extension SurveyHandler {
    
    // remove all current fences
    func dumpMonitoredRegions() {
        for region in locationManager.monitoredRegions { locationManager.stopMonitoring(for: region) }
    }
    
    // returns true the user is in the fence, can probably change this slightly
    func testContentsOfRegion(_ region: CLCircularRegion) -> Bool {
        let currentLat = locationManager.location?.coordinate.latitude
        let currentLong = locationManager.location?.coordinate.longitude
        let currentCoordinate = CLLocationCoordinate2D(latitude: currentLat!, longitude: currentLong!)
        
        if region.contains(currentCoordinate) { return true }
        return false
    }
    
    // sets up the fences so they can be monitored
    func startMonitoringGeofences(with fences: inout [NewFence]) {
        
        // checks if there is space, if not adds the closest fences to the user
        if fences.count < maxGeoFences {
            for fence in fences {
                let center = CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude)
                let region = CLCircularRegion(center: center, radius: fence.radius, identifier: fence.id)
                locationManager.startMonitoring(for: region)
            }
        } else {
            // if the app can't get the current location, put in the first 20
            let sortedFences = fences.sorted{ return $0.distance < $1.distance }
            for i in 0..<maxGeoFences {
                let center = CLLocationCoordinate2D(latitude: sortedFences[i].latitude, longitude: sortedFences[i].longitude)
                let region = CLCircularRegion(center: center, radius: sortedFences[i].radius, identifier: sortedFences[i].id)
                locationManager.startMonitoring(for: region)
            }
        }
    }
    
    // Handles when the user walks into survey area, sends notification and adjusts table
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.sendNotification(notificationTitle: "A Survey is ready", notificationBody: "complete survey")
        if let context = self.container?.viewContext {
            context.perform {
                if let survey = try? Survey.findSurveyWithFenceID(region.identifier, in: context) {
                    for surveys in survey {
                        surveys.sectionName = "Ready to Complete"
                    }
                } else {
                    print("No survey found matching this fence id.")
                    self.locationManager.stopMonitoring(for: region)
                    return
                }
                try? context.save()
            }
        }
    }
    
    // Handles when the user leaves the area, updates tables, and will send surveys to server
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if let context = self.container?.viewContext {
            context.perform {
                
                // find matching surveys in the database
                guard let surveys = try? Survey.findSurveyWithFenceID(region.identifier, in: context) else {
                    print("There was no survey matching this fenceID.")
                    self.locationManager.stopMonitoring(for: region)
                    return
                }
                
                for survey in surveys {
                    if survey.isComplete {
                        
                        // send the completed survey to the server
                        if self.surveyCompleted(with: survey.id!) {
                            let fence = Survey.findFenceFromSurvey(survey, matching: region.identifier)
                            
                            // notify user survey has been sent to the server
                            self.sendNotification(notificationTitle: "Survey sent!", notificationBody: "Your completed survey has been sent to the server.")
                            
                            // if there isn't a remaining survey using the fence, remove the fence from monitored regions
                            if surveys.count <= 1 || !surveys.contains(where: {$0.isComplete == false}) {
                                let center = CLLocationCoordinate2D(latitude: fence!.latitude, longitude: fence!.longitude)
                                let region = CLCircularRegion(center: center, radius: fence!.radius, identifier: fence!.id!)
                                self.locationManager.stopMonitoring(for: region)
                            }
                            survey.removeFromFences(fence!)
                            
                        } else {
                            print("Failed to Post to server, resetting survey.")
                            survey.isComplete = false
                        }
                        
                    } else {
                        // make sure the survey isn't in another fence.
                        if var fences = survey.fences?.allObjects as? [Fence], fences.count > 1 {
                            fences.remove(at: fences.index(where: {$0.id == region.identifier})!)
                            for fence in fences {
                                let fenceCenter = CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude)
                                let fenceRegion = CLCircularRegion(center: fenceCenter, radius: fence.radius, identifier: fence.id!)
                                if self.testContentsOfRegion(fenceRegion) {
                                    survey.sectionName = "Ready to Complete"
                                    break
                                } else { survey.sectionName = "Surveys" }
                            }
                        } else { survey.sectionName = "Surveys" }
                    }
                }
                try? context.save()
            }
        }
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
}
