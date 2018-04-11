//
//  User.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 2/25/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

// Messing with the idea of a Singleton class (or struct in this instance).

import Foundation
import CoreLocation

//var shared: User = User(email: "jasonwest1013@yahoo.com")

// test struct used to possibly keep user defined data, there should only be one instance
// only need to set email, everything else will get default values to start
struct User {
    // Singleton for now at least
    static var shared: User = User(email: "jasonwest1013@yahoo.com")
    let locationManager = SurveyHandler.shared.locationManager
    
    let email: String
    var radiusSetting: Double                             // set in settings
    var latitude: Double?
    var longitude: Double?
    var lengthOfSurveyHistory: Int
    var timeOutRequest: Int
    
    init(email: String) {
        self.email = email
        self.radiusSetting = 100
        self.lengthOfSurveyHistory = 50
        self.timeOutRequest = 3
    }
    
    mutating func updateUserCoordinates() {
        self.latitude = locationManager.location?.coordinate.latitude
        self.longitude = locationManager.location?.coordinate.longitude
    }
    
    mutating func checkDistance() -> Bool {
        if self.latitude != nil && self.longitude != nil {
            guard let lat = locationManager.location?.coordinate.latitude else {return false}
            guard let long = locationManager.location?.coordinate.longitude else {return false}
            let location = CLLocation(latitude: lat, longitude: long)
            if location.distance(from: CLLocation(latitude: self.latitude!, longitude: self.longitude!)) >= radiusSetting {
                return true
            }
            return false
        } else {
            return false
        }
    }

}
