//
//  DBManager.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 3/10/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit

class DBManager: NSObject {
    // Make a Singleton
    static let shared: DBManager = DBManager()
    
    // Properties
    private let databaseFileName = "SurveyDatabase.sqlite"
    private var database: FMDatabase!
    
    // Table properties
    private let field_SurveyID = "surveyID"
    private let field_SurveyName = "surveyName"
    private let field_Latitude = "latitude"
    private let field_Longitude = "longitude"
    // let field_Questions = "surveyQuestions"
    
    override init() {
        super.init()
        let fileURL = try! FileManager.default
        .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        .appendingPathComponent(databaseFileName)
        
        self.database = FMDatabase(url: fileURL)
    }

    
    func openDatabase() -> Bool {
        guard database.open() else {
            print("Cannot open database.")
            return false
        }
        print("Database open.")
        return true
    }
    
    func createTable() {
        let createSurveyHistoryTableQuery = """
                                            create table survey(
                                            \(field_SurveyID) integer primary key not null,
                                            \(field_SurveyName) text not null,
                                            \(field_Latitude) real not null,
                                            \(field_Longitude) real not null)
                                            """
        if openDatabase() {
            do {
                try database.executeUpdate(createSurveyHistoryTableQuery, values: nil)
            } catch {
                print("Table Creation failed: \(error.localizedDescription)")
            }
            database.close()
        }
    }
        
    
    func insertSurveyIntoTable(identifier id: String, name surveyName: String, latitude lat: Double, longitude long: Double) {
        let insertSurvey =  "insert into survey (\(field_SurveyID), \(field_SurveyName), \(field_Latitude), \(field_Longitude)) values (?, ?, ?, ?)"
        
        if openDatabase() {
            do {
                try database.executeUpdate(insertSurvey, values: ["\(id)","\(surveyName)","\(lat)","\(long)"])
            } catch {
                print("Insert failed: \(error.localizedDescription)")
            }
            database.close()
        }
        
    }

    
}
