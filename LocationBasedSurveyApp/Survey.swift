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
        request.predicate = NSPredicate(format: "id = %@", surveyInfo.id)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "database inconsistency")
                return matches[0]
            }
        } catch { throw error }
        
        // otherwise, make new survey in database
        let survey = Survey(context: context)
        survey.id = surveyInfo.id
        survey.name = surveyInfo.name
        survey.url = surveyInfo.url
        if surveyInfo.isSelected {
            survey.sectionName = "Ready to Complete"
        }
        for fence in surveyInfo.fences {
            do {
                let fence = try Fence.createFence(matching: fence, in: context)
                survey.addToFences(fence)
            } catch { print("Couldn't add fence.") }
        }
        return survey
    }
    
    // finds the survey in the database with the mathing fence id passed as a parameter
    class func findSurveyWithFenceID(_ identifier: String, in context: NSManagedObjectContext) throws -> [Survey] {
        let request: NSFetchRequest<Survey> = Survey.fetchRequest()
        request.predicate = NSPredicate(format: "any fences.id = %@", identifier)
        do {
            let matchingSurvey = try context.fetch(request)
            return matchingSurvey
        } catch { throw error }
    }
    
    // finds the survey in the database with the matching survey id
    class func findSurveyWithSurveyID(_ identifier: String, in context: NSManagedObjectContext) throws -> [Survey] {
        let request: NSFetchRequest<Survey> = Survey.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", identifier)
        do {
            let matchingSurvey = try context.fetch(request)
            return matchingSurvey
        } catch { throw error }
    }
    
    // returns all the survey's fences matching the identifier
    class func findFenceFromSurvey(_ survey: Survey, matching identifier: String) -> Fence? {
        let fences = survey.fences?.allObjects as? [Fence]
        if let index = fences?.index(where: {$0.id == identifier}) { return fences?[index] }
        return nil
    }
    
    // returns surveys that are either completed or not completed
    class func getSurveysThat(are completed : Bool, in context: NSManagedObjectContext) throws -> [Survey] {
        let request: NSFetchRequest<Survey> = Survey.fetchRequest()
        if completed {
            request.predicate = NSPredicate(format: "isComplete = YES")
        } else { request.predicate = NSPredicate(format: "isComplete = NO") }
        
        do {
            let surveys = try context.fetch(request)
            return surveys
        } catch { throw error }
    }
    
    // Removes survey from the database, may not need to return but left it open, will remove all found surveys (should only be one)
    class func removeFromDatabaseWith(survey identifier: String, in context: NSManagedObjectContext) throws -> [Survey] {
        do {
            let surveys = try findSurveyWithSurveyID(identifier, in: context)
            for survey in surveys {
                context.delete(survey)
            }
            return surveys
        } catch { throw error }
    }
    
    // Removes all uncompleted surveys
    class func removeEverythingFromDatabase(in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Survey")
        request.predicate = NSPredicate(format: "isComplete = NO")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try context.execute(deleteRequest)
        } catch { throw error }
    }
}
