//
//  AppDelegate.swift
//  LocationBasedSurveyApp
//
//  Created by Mitchell Lombardi on 10/12/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit
import UserNotifications
import GoogleMaps
import CoreData
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    static var persistentContainer: NSPersistentContainer {return (UIApplication.shared.delegate as! AppDelegate).persistentContainer}
    static var viewContext: NSManagedObjectContext {return persistentContainer.viewContext}
    let userDefaults = UserDefaults.standard
    let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        GMSServices.provideAPIKey("AIzaSyAfT_vi41OGKGWv4TQWEKn-peBOaxu6jpQ")
        UNUserNotificationCenter.current().delegate = self
        
        // to show tutorial screen on first launch
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "isFirstTime") == nil {
            defaults.set("No", forKey:"isFirstTime")
            defaults.synchronize()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "TutorialViewController") as! TutorialViewController
            self.window?.rootViewController = viewController
            self.window?.makeKeyAndVisible()
        }
        
        // do this here so surveys can populate after tutorial
        locationManager.requestAlwaysAuthorization()
        
        // if the user defaults are nil, set them to their default values
        if userDefaults.value(forKey: "timeout") == nil || userDefaults.value(forKey: "userUpdateRadius") == nil {
            userDefaults.set(3218, forKey: "userUpdateRadius")
            userDefaults.set(10800, forKey: "timeout")
        }
        return true
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LocationBasedSurveyApp")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) { completionHandler(.alert) }
}

