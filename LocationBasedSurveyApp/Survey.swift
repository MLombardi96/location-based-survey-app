//
//  Survey.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/11/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit
import CoreData

class Survey: NSManagedObject {
    
    // either finds existing survey or creates a new one in the database
    class func findOrCreateSurvey(matching surveyInfo: NewSurvey, in context: NSManagedObjectContext) throws -> Survey? {
        let request: NSFetchRequest<Survey> = Survey.fetchRequest()
        guard let surveyId = surveyInfo.id else { return nil }                      // may want to change this
        request.predicate = NSPredicate(format: "id = %@", surveyId)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        // otherwise, make new survey in database
        let survey = Survey(context: context)
        survey.id = surveyInfo.id
        survey.name = surveyInfo.name
        survey.latitude = surveyInfo.latitude
        survey.longitude = surveyInfo.longitude
        survey.radius = surveyInfo.radius
        survey.isComplete = surveyInfo.isComplete
        return survey
        
    }
    
    // finds the survey in the database with the mathing identifier passed as a parameter
    class func findSurveyWith(matching identifier: String, in context: NSManagedObjectContext) throws -> Survey {
        let request: NSFetchRequest<Survey> = Survey.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", identifier)
        
        do {
            let matchingSurvey = try context.fetch(request)
            return matchingSurvey[0]
        } catch {
            throw error
        }
        
    }
    
    // Removes survey from the database, may not need to return but left it open
    // ** haven't tested yet **
    class func removeFromDatabaseWith(matching identifier: String, in context: NSManagedObjectContext) throws -> Survey {
        do {
            let survey = try findSurveyWith(matching: identifier, in: context)
            context.delete(survey)
            return survey
        } catch {
            throw error
        }
    }
}
