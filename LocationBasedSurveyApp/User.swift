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
    
    let email: String?
    var radiusSetting: Double                             // set in settings
    var latitude: Double?
    var longitude: Double?
    var lengthOfSurveyHistory: Int
    var timeOutRequest: Int
    
    init(email: String) {
        self.email = email
        self.radiusSetting = 100
        self.lengthOfSurveyHistory = 50
        self.timeOutRequest = 3             // hours
        self.latitude = 0
        self.longitude = 0
    }
    
    mutating func setUserCoordinates(coordinates: CLLocationCoordinate2D) {
        self.latitude = coordinates.latitude
        self.longitude = coordinates.longitude
    }
    
    func getUserCoordinates() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude!, longitude: self.longitude!)
    }
    
    mutating func resetGeofence() {
        let location = SurveyHandler.shared.locationManager.location
        self.latitude = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
        let center = CLLocationCoordinate2D(latitude: self.latitude!, longitude: self.longitude!)
        SurveyHandler.shared.createGeofence(with: CLCircularRegion(center: center, radius: radiusSetting, identifier: "User"))
    }

}
