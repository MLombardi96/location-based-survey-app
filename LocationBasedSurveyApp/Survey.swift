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
    
    //let locationNotification = LocationNotification()
    
    //MARK: Properties
    var id: String?
    var name: String
    //var shortDescription: String // Used when the survey questions are available
    var latitude: Double
    var longitude: Double
    var radius: Double
    var isSelected = false
 
    //MARK: Initialization
    init?(_ survey: inout Root.Survey) {
        
        self.id = survey.ID
        self.name = survey.Name
        self.latitude = survey.LatLng[0]
        self.longitude = survey.LatLng[1]
        self.radius = survey.Radius
        //self.shortDescription = survey.Description
    }
    
    init() {
        self.id = nil
        self.name = "No History"
        self.latitude = 0
        self.longitude = 0
        self.radius = 0
    }
    
}
