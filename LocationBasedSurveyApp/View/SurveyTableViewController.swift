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
    
    private var container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer { didSet { updateUI() } }
    
    private var fetchedResultsController: NSFetchedResultsController<Survey>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl?.addTarget(self, action: #selector(HistoryTableViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
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
            try? fetchedResultsController?.performFetch()
            tableView.reloadData()
        }
    }
    
    // Refresh Methods
    override func viewDidAppear(_ animated: Bool) {
        updateUI()
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        updateUI()
        refreshControl.endRefreshing()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "AvailableSurveysTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? AvailableSurveysTableViewCell else {
            fatalError("The dequeue cell is not an instance of HistoryTableViewCell")
        }
        if let currentSurvey = fetchedResultsController?.object(at: indexPath) {
            cell.surveyTitle.text = currentSurvey.name
        }
        return cell
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
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let indexPath = tableView.indexPathForSelectedRow!
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

extension SurveyTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 1
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
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController?.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController?.section(forSectionIndexTitle: title, at: index) ?? 0
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
}



