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

//TODO: setup User and timeout request methods to request more surveys
//TODO: include the picture ability once Colin and Joe figure out what they're doing
//TODO: limit the fences to only 20, repopulate based on User location, may only need to update at request time
class SurveyHandler: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    static let shared: SurveyHandler = SurveyHandler()
    let locationManager: CLLocationManager
    let maxGeoFences = 20
    var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    override public init() {
        
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
        
        // removes all fences
        dumpMonitoredRegions()
        
        // starts request process
        guard let currentLat = locationManager.location?.coordinate.latitude else {return}
        guard let currentLong = locationManager.location?.coordinate.longitude else {return}
        let userLatitude = Double(currentLat)
        let userLongitude = Double(currentLong)
        
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
            if error != nil { print("There was an error sending a POST request to the server. Error: \(String(describing: error))") }
            
            // Parse JSON file, can change to decoder once JSON format is fixed
            var newSurvey = [NewSurvey]()
            var newRegions: [CLCircularRegion] = []
            let userCoordinates = CLLocationCoordinate2D(latitude: userLatitude, longitude: userLongitude)
            
            if let jsonData = data {
                let jsonFile = JSON(jsonData)
                
                // Create incoming fences
                let arrayFences = jsonFile["regions"].arrayValue
                for region in arrayFences {
                    
                    // Create new fence
                    let newFence = NewFence(
                        id: region["id"].stringValue,
                        name: region["name"].stringValue,
                        latitude: Double(String(format: "%.6f", region["center"]["lat"].doubleValue))!,
                        longitude: Double(String(format: "%.6f", region["center"]["lng"].doubleValue))!,
                        radius: region["radius"].doubleValue)
                    
                    // Start monitoring fences
                    let center = CLLocationCoordinate2D(latitude: newFence.latitude, longitude: newFence.longitude)
                    let fence = CLCircularRegion(center: center, radius: newFence.radius, identifier: newFence.id)
                    newRegions.append(fence)
                    
                    // append newSurveys to be added to the database
                    let surveyArray = region["surveys"].arrayValue
                    for survey in surveyArray {
                        let surveyID = survey["id"].stringValue
                        if newSurvey.isEmpty || !newSurvey.contains(where: {$0.id == surveyID}) {
                            newSurvey.append(NewSurvey(
                                id: surveyID,
                                name: survey["name"].stringValue,
                                url: survey["URL"].stringValue,
                                isSelected: self.testContentsOfRegion(fence),
                                fences: [newFence]
                            ))
                        } else if let index = newSurvey.index(where: {$0.id == surveyID}) {
                            if !newSurvey[index].isSelected {
                                newSurvey[index].isSelected = self.testContentsOfRegion(fence)
                            }
                            newSurvey[index].fences.append(newFence)
                        }
                    }
                }
                self.startMonitoringGeofences(with: &newRegions, user: userCoordinates)
                self.updateDatabase(with: newSurvey)
            }
        }
        task.resume()
    }
    
    //MARK: Survey Complete
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
            if error != nil { print("There was an error sending a POST request to the server. Error: \(String(describing: error))") }
            if let jsonData = data {
                let jsonFile = JSON(jsonData)
                print(jsonFile.rawValue)  //empty?
            }
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
    
    // remove all current fences
    func dumpMonitoredRegions() {
        for region in locationManager.monitoredRegions { locationManager.stopMonitoring(for: region) }
    }
    
    // returns true the user is in the fence, can probably change this slightly
    func testContentsOfRegion(_ region: CLCircularRegion) -> Bool {
        let currentLat = locationManager.location?.coordinate.latitude
        let currentLong = locationManager.location?.coordinate.longitude
        let currentCoordinate = CLLocationCoordinate2D(latitude: currentLat!, longitude: currentLong!)
        
        if region.contains(currentCoordinate) {
            return true
        }
        return false
    }
    
    // sets up the fences so they can be monitored
    func startMonitoringGeofences( with regions: inout [CLCircularRegion], user coordinates: CLLocationCoordinate2D) {
        
        // Create user fence
        let radius = UserDefaults.standard.double(forKey: "userUpdateRedius")
        let userRegion = CLCircularRegion(center: coordinates, radius: radius, identifier: "User")
        locationManager.startMonitoring(for: userRegion)
        
        // checks if there is space, if not adds the closest fences to the user
        if regions.count < maxGeoFences {
            for region in regions { locationManager.startMonitoring(for: region) }
        } else {
            let userLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            regions.sort{
                let firstLocation = CLLocation(latitude: $0.center.latitude, longitude: $0.center.longitude)
                let secondLocation = CLLocation(latitude: $1.center.latitude, longitude: $1.center.longitude)
                return firstLocation.distance(from: userLocation) < secondLocation.distance(from: userLocation)
            }
            for i in 0..<maxGeoFences { locationManager.startMonitoring(for: regions[i]) }
        }
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
                } catch { print("Could not locate Survey with \(region.identifier) in database.") }
                try? context.save()
            }
        }
    }
    
    // Handles when the user leaves the area, updates tables, and will send surveys to server
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if region.identifier == "User" {
            sendNotification(notificationTitle: "Location Changed", notificationBody: "Your surveys have been reset.")
            requestSurveys()
        }
        
        if let context = self.container?.viewContext {
            context.perform {
                do {
                    // find matching surveys in the database
                    let surveys = try Survey.findSurveyWithFenceID(region.identifier, in: context)
                    for survey in surveys {
                        
                        if survey.isComplete {
                            
                            // send the completed survey to the server
                            if self.surveyCompleted(with: survey.id!) {
                                guard let fence = Survey.findFenceFromSurvey(survey, matching: region.identifier) else {
                                    print("Couldn't find fence contained in survey.")
                                    survey.isComplete = false
                                    return
                                }
                                
                                // notify user survey has been sent to the server
                                self.sendNotification(notificationTitle: "Survey sent!", notificationBody: "Your completed survey has been sent to the server.")
                                
                                // if there isn't a remaining survey using the fence, remove the fence from monitored regions
                                if surveys.count <= 1 || !surveys.contains(where: {$0.isComplete == false}) {
                                    let center = CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude)
                                    let region = CLCircularRegion(center: center, radius: fence.radius, identifier: fence.id!)
                                    self.locationManager.stopMonitoring(for: region)
                                }
                    
                                // remove fence from survey
                                survey.removeFromFences(fence)
                                
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
                                    print(fence.id!)
                                    if self.testContentsOfRegion(fenceRegion) {
                                        survey.sectionName = "Ready to Complete"
                                        break
                                    } else { survey.sectionName = "Surveys" }
                                }
                            } else { survey.sectionName = "Surveys" }
                        }
                    }
                } catch { print("Could not location Survey with id \(region.identifier) in database.") }
                
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


