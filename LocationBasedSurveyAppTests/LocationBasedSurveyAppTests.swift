//
//  LocationBasedSurveyAppTests.swift
//  LocationBasedSurveyAppTests
//
//  Created by Mitchell Lombardi on 10/12/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import XCTest
@testable import LocationBasedSurveyApp

class LocationBasedSurveyAppTests: XCTestCase {
    
    //MARK: Survey Class Tests
    
    // Confirm the Survey initializer returns a Survey object.
    func testSurveyInitializationFails() {
        
        // Empty survey name test
        let emptySurveyName = Survey.init(name: "", shortDescription: "No survey name", latitude: 0, longitude: 0, radius: 50)
        XCTAssertNil(emptySurveyName)
        
        // Empty Survey description test
        let emptySurveyDecription = Survey.init(name: "No description", shortDescription: "", latitude: 0, longitude: 0, radius: 50)
        XCTAssertNil(emptySurveyDecription)
        
        let lowBoundsLatitude = Survey.init(name: "Lat Low", shortDescription: "Bounds", latitude: -91, longitude: 0, radius: 50)
        XCTAssertNil(lowBoundsLatitude)
        
    }
    
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
