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

// test struct used to possibly keep user defined data, there should only be one instance
// only need to set email, everything else will get default values to start
struct User {
    // Singleton for now at least
    static var shared: User = User()
    
    let email: String?      // Needs to be set
    var radiusSetting: Double
    var timeOutRequest: Int
    
    init() {
        self.email = nil
        self.radiusSetting = 100
        self.timeOutRequest = 3
    }

}
