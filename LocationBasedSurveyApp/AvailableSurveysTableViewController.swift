//
//  AvailableSurveysTableViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/22/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit

class AvailableSurveysTableViewController: UITableViewController {
    
    //MARK: Properties
    let sections = ["Surveys Ready", "Surveys"]
    var totalSurveys = [[Survey]]()
    let surveyHandler = SurveyHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl?.addTarget(self, action: #selector(AvailableSurveysTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        totalSurveys.append(surveyHandler.surveysReadyToComplete)
        totalSurveys.append(surveyHandler.surveysWithinArea)
    }
    
    //MARK: Refreshing data methods
    // refreshes the tables when the view appears on screen
    override func viewDidAppear(_ animated: Bool) {
        totalSurveys.removeAll()
        totalSurveys.append(surveyHandler.surveysReadyToComplete)
        totalSurveys.append(surveyHandler.surveysWithinArea)
        self.tableView.reloadData()
    }
    
    // Also refreshes the tables when the screen is pulled down
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        totalSurveys.removeAll()
        totalSurveys.append(surveyHandler.surveysReadyToComplete)
        totalSurveys.append(surveyHandler.surveysWithinArea)
        self.tableView.reloadData()
        refreshControl.endRefreshing()
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
        let survey = totalSurveys[indexPath.section][indexPath.row]
        cell.surveyTitle.text = survey.name
        //cell.surveyDemoDescription.text = survey.shortDescription

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = totalSurveys[indexPath.section][indexPath.row]
        if selectedCell.isSelected {
            self.performSegue(withIdentifier: "ReadySurvey", sender: self)
        } else {
            self.performSegue(withIdentifier: "NotReadySurvey", sender: self)
        }
    }
    
    // MARK: - Navigation
    // passes the survey to the correct ViewController segue based on the isSelected value
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let survey = totalSurveys[(tableView.indexPathForSelectedRow?.section)!][(tableView.indexPathForSelectedRow?.row)!]
        if segue.identifier == "ReadySurvey" {
            if let destinationViewController = segue.destination as? SurveyQuestionsViewController {
                destinationViewController.survey = survey
            }
        } else {
            if let destinationViewController = segue.destination as? GoogleMapsViewController {
                destinationViewController.survey = survey
            }
        }
    }
}
