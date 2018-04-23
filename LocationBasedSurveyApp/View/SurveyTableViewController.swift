//
//  HistoryTableViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 2/25/18.
//  Copyright © 2018 Mitchell Lombardi. All rights reserved.
//

import UIKit
import CoreData

class SurveyTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    //MARK: Properties
    private var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer { didSet { updateUI() } }
    private var fetchedResultsController: NSFetchedResultsController<Survey>?
    var emptyTable = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl?.addTarget(self, action: #selector(SurveyTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    internal func updateUI() {
        if let context = container?.viewContext {
            let request: NSFetchRequest<Survey> = Survey.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "sectionName", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
            request.predicate = NSPredicate(format: "isComplete = NO")
            fetchedResultsController = NSFetchedResultsController<Survey>(
                fetchRequest: request,
                managedObjectContext: context,
                sectionNameKeyPath: "sectionName",
                cacheName: nil
            )
            do {
                // test if data for table is present
                if try context.fetch(request).isEmpty {
                    emptyTable = true
                } else {
                    emptyTable = false
                }
                
                try fetchedResultsController?.performFetch()
                tableView.reloadData()
            } catch {
                print("Could not load data from database.")
            }
        }
    }
    
    //MARK: Refresh Methods
    override func viewDidAppear(_ animated: Bool) { updateUI() }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        updateUI()
        refreshControl.endRefreshing()
    }
    
    //MARK: Unique Tableview methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AvailableSurveysTableViewCell", for: indexPath)
        
        if let currentSurvey = fetchedResultsController?.object(at: indexPath) {
            cell.textLabel?.text = currentSurvey.name
            //cell.detailTextLabel?.text = currentSurvey.fenceName
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedCell = fetchedResultsController?.object(at: indexPath) {
            if selectedCell.sectionName == "Ready to Complete" {
                self.performSegue(withIdentifier: "ReadySurvey", sender: nil)
            } else {
                self.performSegue(withIdentifier: "NotReadySurvey", sender: nil)
            }
        }
    }
    
    //MARK: NSFetchResultsController methods
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert: tableView.insertSections([sectionIndex], with: .fade)
        case .delete: tableView.deleteSections([sectionIndex], with: .fade)
        default: break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert: tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete: tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update: tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // MARK: Navigation methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        let selectedSurvey = fetchedResultsController?.object(at: indexPath)
        if segue.identifier == "ReadySurvey" {
            if let destinationViewController = segue.destination as? SurveyQuestionsViewController {
                destinationViewController.survey = selectedSurvey
            }
        } else {
            if let destinationViewController = segue.destination as? GoogleMapsViewController {
                destinationViewController.survey = selectedSurvey
            }
        }
    }
    
}

// Contains tableview methods used with the fetched request controller
extension SurveyTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if !emptyTable {
            tableView.backgroundView = nil
            return fetchedResultsController?.sections?.count ?? 1
        } else {
            // otherwise show centered label
            let emptyLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            emptyLabel.text = "No Surveys Available"
            emptyLabel.textColor = UIColor.black
            emptyLabel.textAlignment = .center
            tableView.backgroundView = emptyLabel
            tableView.separatorStyle = .none
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController?.sections, sections.count > 0 {
            return sections[section].name
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
    }
    /*
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }*/
    
}



