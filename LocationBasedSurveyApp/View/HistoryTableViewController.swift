//
//  HistoryTableViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 2/25/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit

class HistoryTableViewController: UITableViewController {
    
    var surveyHistoryList = [Survey]()
    let surveyHandler = SurveyHandler.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl?.addTarget(self, action: #selector(HistoryTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        // load surveys from memory using the surveyHandler
        // if no surveys, append the empty survey
        surveyHistoryList = surveyHandler.getSurveyHistory()
    }
    
    // Refresh Methods
    override func viewDidAppear(_ animated: Bool) {
        surveyHistoryList.removeAll()
        surveyHistoryList = surveyHandler.getSurveyHistory()
        self.tableView.reloadData()
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        surveyHistoryList.removeAll()
        surveyHistoryList = surveyHandler.getSurveyHistory()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return surveyHistoryList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "HistoryTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? HistoryTableViewCell else {
            fatalError("The dequeue cell is not an instance of HistoryTableViewCell")
        }
        let history = surveyHistoryList[indexPath.row]
        cell.historyTitle.text = history.name
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
