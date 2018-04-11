//
//  NewSurvey.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/11/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import Foundation
import CoreLocation

/****
 * Survey Data Model
 ***/
class NewSurvey {
    
    //MARK: Properties
    var id: String?
    var name: String
    var surveys: [String]
    var latitude: Double
    var longitude: Double
    var radius: Double
    var isSelected = false
    var isComplete = false
    
    var center: CLLocationCoordinate2D
    var region: CLCircularRegion
    
    //MARK: Initialization
    init?(_ newSurvey: inout Fence.Regions) {
        
        self.id = newSurvey.id
        self.name = newSurvey.name
        self.latitude = newSurvey.center.lat
        self.longitude = newSurvey.center.lng
        self.radius = newSurvey.radius
        self.surveys = newSurvey.surveys
        self.center = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        self.region = CLCircularRegion(center: self.center, radius: self.radius, identifier: self.id!)
        //self.shortDescription = survey.Description
    }
    
    init(_ name: String, identifier id: String, surveyID surID: [String], latitude lat: Double, longitude long: Double, radius rad: Double) {
        self.id = id
        self.name = name
        self.surveys = surID
        self.latitude = lat
        self.longitude = long
        self.radius = rad
        self.center = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        self.region = CLCircularRegion(center: self.center, radius: self.radius, identifier: self.id!)
    }
}
