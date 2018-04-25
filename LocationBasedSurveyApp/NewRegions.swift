//
//  NewSurvey.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/11/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import Foundation

struct NewSurvey {
    //MARK: Properties
    var id: String
    var name: String
    var url: String
    var isSelected = false
    var fences: [NewFence]
}

struct NewFence {
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double
}
