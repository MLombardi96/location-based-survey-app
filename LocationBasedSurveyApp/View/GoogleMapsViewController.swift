//
//  GoogleMapsViewController.swift
//  LocationBasedSurveyApp
//
//  Created by Jason West on 12/23/17.
//  Copyright © 2017 Mitchell Lombardi. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import MapKit

class GoogleMapsViewController: UIViewController, CLLocationManagerDelegate {
    
    //MARK: Properties
    var survey: Survey?
    let locationManager = CLLocationManager()
    var mapView = GMSMapView()
    var surveyLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // CLLocationManager initialization
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
        }
        
        // set the survey locaiton when the view loads
        if let latitude = survey?.latitude, let longitude = survey?.longitude {
            surveyLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let camera = GMSCameraPosition.camera(withTarget: surveyLocation!, zoom: 15.0)
            mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            view = mapView
            
            // survey location marker
            let surveyMarker = GMSMarker()
            surveyMarker.position = surveyLocation!
            surveyMarker.title = survey!.name
            surveyMarker.map = mapView
        }
    
    }
    
    //MARK: Actions
    @IBAction func getDirections(_ sender: UIBarButtonItem) {
        let testURL = URL(string: "comgooglemaps://")!
        guard let currentSurvey = survey else {
            print("No survey exists to map.")
            return
        }
        
        // trys to open Google Maps otherwise defaults to Apple Maps
        if UIApplication.shared.canOpenURL(testURL) {
            let directionRequest = "comgooglemaps://?saddr=&daddr=\(currentSurvey.latitude),\(currentSurvey.longitude)&directionsmode=driving"
            let directionsURL = URL(string: directionRequest)!
            UIApplication.shared.open(directionsURL, options: [:], completionHandler: nil)
        } else {
            let coordinate = CLLocationCoordinate2DMake(currentSurvey.latitude,currentSurvey.longitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            if let surveyLocationName = currentSurvey.fenceName {
                mapItem.name = "\(surveyLocationName) Survey"
                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
            }
        }
    }
    
    //MARK: Location manager methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = manager.location!.coordinate // convert user's location to CLLocationCoordinate2D
        let inset = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100) // area around the two bounds
        
        let bounds = GMSCoordinateBounds(coordinate: surveyLocation!, coordinate: currentLocation)
        let camera = mapView.camera(for: bounds, insets: inset)
        mapView.camera = camera!
        mapView.isMyLocationEnabled = true
        locationManager.stopUpdatingLocation()
    }

}
