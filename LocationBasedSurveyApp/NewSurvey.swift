//
//  NewSurvey.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/11/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import Foundation
import CoreLocation

struct NewSurvey {
    
    //MARK: Properties
    var fenceID: String
    var surveyID: String
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    var url: String
    var isSelected = false
    
}
