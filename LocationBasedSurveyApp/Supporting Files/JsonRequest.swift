//
//  JsonRequest.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/20/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import Foundation

struct SurveyFence: Decodable {
    let regions : [Regions]
    
    struct Regions: Decodable {
        let name: String
        let id: String
        let surveys : [Surveys]
        
        struct Surveys: Decodable {
            let name: String
            let id: String
            let active: Bool
            let URL: String
        }
        
        let center: Center
        
        struct Center: Decodable {
            let lat: Double
            let lng: Double
        }
        
        let radius: Double
    }
}






