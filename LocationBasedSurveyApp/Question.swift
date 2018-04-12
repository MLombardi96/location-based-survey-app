//
//  Question.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 4/11/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit
import CoreData

class Question: NSManagedObject {
    
    class func findOfCreateQuestion(with matching: NewQuestion, in context: NSManagedObjectContext) throws -> Question? {
        //check if anything is in the database
        let request: NSFetchRequest<Question> = Question.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", matching.id)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "database inconsistency")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        //otherwise - add to database
        let question = Question(context: context)
        question.id = matching.id
        question.number = Int32(matching.number)
        return question
    }
    
    class func findQuestionWith(matching identifier: String, in context: NSManagedObjectContext) throws -> Question {
        let request: NSFetchRequest<Question> = Question.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", identifier)
        do {
            let matchingQuestion = try context.fetch(request)
            return matchingQuestion[0]
        } catch {
            throw error
        }
    }
    
}
