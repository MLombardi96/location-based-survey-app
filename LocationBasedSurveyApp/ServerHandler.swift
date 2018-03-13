//
//  ServerHandler.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 2/25/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import Foundation

// waiting for Colin to update the testSurveys/testFences
struct ServerHandler {
    
    let serverURL = "http://sdp-2017-survey.cse.uconn.edu/test"
    var timeOutLength = User.shared.timeOutRequest
    
    func serverRequestSurveyLocations() {
        guard let url = URL(string: serverURL) else {return}
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // create a dictionary to represent the JSON object
        guard let email = User.shared.email else {return}
        let jsonObject: [String: Any] = [
            "email": email,
            "LatLng": [
                User.shared.latitude,
                User.shared.longitude
            ]
        ]

        // turn dictionary into JSON object
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }

        
        // Add HTTP Headers
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
        }
            
    }

    // once the fences have been setup request questions
    func serverRequestSurveyQuestions() {
        
    }
    
    // send completed surveys back to the server
    func sendSurveyQuesions() {
        
    }
    

}
