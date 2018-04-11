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

//TODO: add a maximum of 20 and cache the rest (Database?)
//TODO: when questions are available manage a 'short description' for tableView
//TODO: create function that parses and sets up currentSurveys

struct Fence: Codable {
    struct Regions: Codable {
        let name: String
        let id: String
        let surveys: [String]
        struct Center: Codable {
            let lat: Double
            let lng: Double
        }
        let center: Center
        let radius: Double
    }
    var regions: [Regions]
}

/****
 * Handles parsing json files for survey data, creating surveys, creating geofences, and
 * displaying notifications. 
 ****/
class SurveyHandler: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    static let shared: SurveyHandler = SurveyHandler()
    let serverURL = "http://sdp-2017-survey.cse.uconn.edu/testFence"
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
    
    //MARK: Methods
    // parses JSON file and puts surveys in correct lists
    func requestSurveyFences() {
        if let url = NSURL(string: "http://sdp-2017-survey.cse.uconn.edu/testFence") {
            let urlSession = URLSession.shared
            let request = URLRequest(url: url as URL)
            
            let task = urlSession.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    print("There was an error downloading data from the server. Error: \(String(describing: error))")
                }
                do {
                    if let jsonData = data {
                        let fence = try JSONDecoder().decode(Fence.self, from: jsonData)
                        self.updateDatabase(with: fence)
                    }
                } catch {
                    print("Could not get data from server")
                }
                var surveyID: [String] = []
                let jsonFile = JSON(data)
                let arrayFences = jsonFile["regions"].arrayValue
                for regions in arrayFences {
                    let name = regions["name"].stringValue
                    let id = regions["id"].stringValue
                    let surveyIds = regions["surveys"].arrayValue
                    for ids in surveyIds {
                        surveyID.append(ids.stringValue)
                    }
                    print(surveyID)
                    let lat = regions["center"]["lat"].doubleValue
                    let long = regions["center"]["long"].doubleValue
                    let radius = regions["radius"].doubleValue
                    let newSurvey = NewSurvey(name, identifier: id, surveyID: surveyID, latitude: lat, longitude: long, radius: radius)
                }
                
            }
            task.resume()
        }
    }
    
    // takes a Fence type and loops putting all the surveys in the database
    func updateDatabase(with fence: Fence) {
        // remove all non-completed surveys from database
        // stop monitoring geofences of removed surveys
        container?.performBackgroundTask { [weak self] context in
            for regions in fence.regions {
                var region = regions
                let newSurvey = NewSurvey(&region)
                self!.createGeofence(with: newSurvey!.region)
                // test and set isSelected value
                _ = try? Survey.findOrCreateSurvey(matching: newSurvey!, in: context)
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
    
    // marks the survey so it is placed in the HistoryViewTable, run on the background
    func userHasCompleted(_ survey: Survey) {
        container?.performBackgroundTask { context in
            do {
                if let surveyID = survey.id {
                    let survey = try Survey.findSurveyWith(matching: surveyID, in: context)
                    survey.isComplete = true
                }
            } catch {
                print("Not possible.")
            }
            try? context.save()
        }
    }
}

// extension that contains all the CLLocaitonManager and UNUserNotification methods
extension SurveyHandler {
    
    func createGeofence(with region: CLCircularRegion) {
        locationManager.startMonitoring(for: region)
    }
    
    // Handles when the user walks into survey area, sends notification and adjusts table
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.sendNotification(notificationTitle: "A Survey is ready", notificationBody: "complete survey")
        if let context = self.container?.viewContext {
            context.perform {
                do {
                    let survey = try Survey.findSurveyWith(matching: region.identifier, in: context)
                    survey.sectionName = "Ready to Complete"
                } catch {
                    print("Could not locate Survey in database.")
                }
                try? context.save()
            }
        }
    }
    
    // Handles when the user leaves the area, updates tables and will post answers to the server
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // send info to server (questions yada yada)
        if let context = self.container?.viewContext {
            context.perform {
                do {
                    let survey = try Survey.findSurveyWith(matching: region.identifier, in: context)
                    survey.sectionName = "Surveys"
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


