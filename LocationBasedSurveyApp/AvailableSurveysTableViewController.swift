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
    var availableSurveys = [Survey]() // Empty array of available survey objects
    
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
        
        availableSurveys += [survey1, survey2]
    }
    
    @IBAction func myUnwindAction(unwindSegue: UIStoryboardSegue) {
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load sample data
        loadSampleSurveys()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableSurveys.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "AvailableSurveysTableViewCell"
        
        // As the user scrolls the cells are reused with the ones off screen
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AvailableSurveysTableViewCell else {
            fatalError("The dequeue cell is not an instance of AvailableSurveysTableViewCell")
        }
        
        // double check this code, needs more with optionals
        let survey = availableSurveys[indexPath.row] // fetches the correct survey from the array
        cell.surveyTitle.text = survey.name
        cell.surveyDemoDescription.text = survey.shortDescription

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // grabs the current selected available survey from array
        // passes it to the GoogleMapsViewController
        let survey = availableSurveys[(tableView.indexPathForSelectedRow?.row)!]
        if let destinationViewController = segue.destination as? GoogleMapsViewController {
            destinationViewController.survey = survey
        }
    }
    

}
