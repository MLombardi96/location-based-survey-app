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
                
                // Double(String(format: "%.6f", regions["center"]["lat"].doubleValue))!
                var newSurveys = [NewSurvey]()
                
                if let jsonData = data {
                    var surveyID: [String] = []
                    let jsonFile = JSON(jsonData)
                    let arrayFences = jsonFile["regions"].arrayValue
                    
                    for regions in arrayFences {
                        let surveyIds = regions["surveys"].arrayValue
                        for ids in surveyIds {
                            surveyID.append(ids.stringValue)
                        }
                        newSurveys.append(NewSurvey(
                            id: regions["id"].stringValue,
                            name: regions["name"].stringValue,
                            surveys: surveyID,
                            latitude: regions["center"]["lat"].doubleValue,
                            longitude: regions["center"]["lng"].doubleValue,
                            radius: regions["radius"].doubleValue,
                            isSelected: false,
                            isComplete: false
                        ))
                    }
                    self.updateDatabase(with: newSurveys)
                }
            }
            task.resume()
        }
    }
    
    
    // MARK: Database methods
    func updateDatabase(with newSurveys: [NewSurvey]) {
        container?.performBackgroundTask{ [weak self] context in
            for survey in newSurveys {
                self?.createGeofence(with: survey.region)
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


