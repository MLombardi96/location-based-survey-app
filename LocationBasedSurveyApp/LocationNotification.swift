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
 */
class LocationNotification: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    private let locationManager: CLLocationManager
    var userLocation: CLLocationCoordinate2D?
    
    override init() {
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        super.init()
        self.locationManager.delegate = self
    }
    
    /****
 `  * Add a new location, can add a max of 20.
    ****/
    func addLocation(latitude lat: Double, longitude long: Double, radius rad: Double, identifier ident: String) {
        let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let region = CLCircularRegion(center: center, radius: rad, identifier: ident)
        locationManager.startMonitoring(for: region)
        print("\(locationManager.monitoredRegions)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification(notificationTitle: "Welcome to \(region.identifier)!", notificationBody: "You made it.")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
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
    
    //TODO: function that returns true is user is within geofence of selected survey
}
