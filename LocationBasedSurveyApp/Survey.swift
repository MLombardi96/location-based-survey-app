//
//  Survey.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/22/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import Foundation 

/****
 * Survey Data Model
 ***/
class Survey {
    
    let locationNotification = LocationNotification()
    
    //MARK: Properties
    var name: String
    var shortDescription: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    var isSelected: Bool
 
    //MARK: Initialization
    init?(name: String, shortDescription: String, latitude: Double, longitude: Double, radius: Double) {
        
        // test cases
        if name.isEmpty || shortDescription.isEmpty {
            return nil
        } else if latitude < -90 || latitude > 90 {
            return nil
        } else if longitude < -180 || longitude > 180 {
            return nil
        } else if radius <= 0 {
            return nil
        }
        
        self.name = name
        self.shortDescription = shortDescription
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.isSelected = false
        
        // create a geofence when a survey is created
        //locationNotification.addGeofenceForSurvey(self)//(latitude: latitude, longitude: longitude, radius: radius, identifier: name)
    }
    
    func inSurveyArea(latitude lat: Double, longitude long: Double) -> Bool {
        if lat == self.latitude && long == self.longitude {
            return true
        }
        return false
    }
    
}
