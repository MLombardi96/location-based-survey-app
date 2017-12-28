//
//  LocationNotification.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 11/21/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import Foundation
import CoreLocation
import UserNotifications

/*
 * Used to create locations and notify the user when they have entered
 * one of the specified regions. Allows the geofences to be handled
 * solely in this class.
 * May want to merge this with the Survey Data Model???
 */
class LocationNotification: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    private let locationManager: CLLocationManager
    var currentSurveysManaged = [Survey]() // keeps list of managed surveys
    
    override init() {
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
    
    /****
 `  * Add a new geofence, can add a max of 20.
    ****/
    func addGeofenceForSurvey(_ survey: Survey) {
        let center = CLLocationCoordinate2D(latitude: survey.latitude, longitude: survey.longitude)
        let region = CLCircularRegion(center: center, radius: survey.radius, identifier: survey.name)
        locationManager.startMonitoring(for: region)
        currentSurveysManaged += [survey] // add to list of managed surveys
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification(notificationTitle: "Welcome to \(region.identifier)!", notificationBody: "You made it.")
        for survey in currentSurveysManaged {
            if region.identifier == survey.name {
                survey.isSelected = true
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        for survey in currentSurveysManaged {
            if region.identifier == survey.name {
                survey.isSelected = false
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
    
    //TODO: function that returns true is user is within geofence of selected survey

