//
//  AvailableSurveysTableViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/22/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

//TODO: figure out how to move surveys based off where the user is
//TODO: setup JSON handler to create surveys
//TODO: change segue to open to survey if survey is in 'Ready Surveys' and Google Maps if 'Not Ready Surveys'

class AvailableSurveysTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    //MARK: Properties
    let sections = ["Surveys Ready", "Surveys"]
    var totalSurveys = [[Survey]]()
    var surveysOutsideRegion = [Survey]() // Empty array of available survey objects
    var surveysInsideRegion = [Survey]()
    
    //MARK: Private Methods
    private func loadSampleSurveys() {
        guard let survey1 = Survey(name: "Bookstore", shortDescription: "What is the bookstore like?", latitude: 41.805179, longitude: -72.253386, radius: 50)
            else {
                fatalError("Unable to initialize survey1")
        }
        
        guard let survey2 = Survey(name: "Home", shortDescription: "Is home really that good?", latitude: 41.908072, longitude: -72.371841, radius: 50)
            else {
                fatalError("Unable to initalize survey2")
        }
        
        guard let survey3 = Survey(name: "Library", shortDescription: "How many books can you read?", latitude: 41.806791, longitude: -72.251737, radius: 50)
            else {
                fatalError("Unable to initalize survey3")
        }
        
        guard  let survey4 = Survey(name: "Dairy Bar", shortDescription: "How good is the ice cream?", latitude: 41.814438, longitude: -72.249793, radius: 50)
            else {
                fatalError("Unable to initialize survey4")
        }
        
        surveysOutsideRegion += [survey1, survey2]
        surveysInsideRegion += [survey3, survey4]
        //availableSurveys = [survey1, survey2]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // load sample data
        loadSampleSurveys()
        
        // add both groups to the total surveys
        totalSurveys.append(surveysInsideRegion)
        totalSurveys.append(surveysOutsideRegion)
    }

    // MARK: - Table View Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.totalSurveys[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "AvailableSurveysTableViewCell"
        
        // As the user scrolls the cells are reused with the ones off screen
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AvailableSurveysTableViewCell else {
            fatalError("The dequeue cell is not an instance of AvailableSurveysTableViewCell")
        }
        
        // double check this code, needs more with optionals
        //let survey = availableSurveys[indexPath.row] // fetches the correct survey from the array
        let survey = totalSurveys[indexPath.section][indexPath.row]
        cell.surveyTitle.text = survey.name
        cell.surveyDemoDescription.text = survey.shortDescription

        return cell
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // grabs the current selected available survey from array
        // passes it to the GoogleMapsViewController
        let survey = totalSurveys[(tableView.indexPathForSelectedRow?.section)!][(tableView.indexPathForSelectedRow?.row)!]
        if let destinationViewController = segue.destination as? GoogleMapsViewController {
            destinationViewController.survey = survey
        }
    }
}
