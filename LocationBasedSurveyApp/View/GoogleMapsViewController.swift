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
    let marker = GMSMarker()
    var surveyLocation: CLLocationCoordinate2D?
    var selectedLocation: CLLocationCoordinate2D?
    
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
        if let latitude = locationManager.location?.coordinate.latitude, let longitude = locationManager.location?.coordinate.longitude {
            let userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let camera = GMSCameraPosition.camera(withTarget: userLocation, zoom: 15.0)
            mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
            mapView.delegate = self
            view = mapView
        
            if let fences = survey?.fences {
                for fence in fences {
                    if let fence = fence as? Fence {
                        surveyLocation = CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude)
                        
                        // Create markers
                        let surveyMarker = GMSMarker()
                        surveyMarker.position = surveyLocation!
                        surveyMarker.title = survey!.name
                        surveyMarker.map = mapView
                        
                        // Create circles
                        let circleCenter = CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude)
                        let circ = GMSCircle(position: circleCenter, radius: fence.radius)
                        
                        circ.fillColor = UIColor(red: 0.35, green: 0, blue: 0, alpha: 0.05)
                        circ.strokeColor = .red
                        circ.strokeWidth = 1
                        circ.map = mapView
                    }
                }
            }
        }
    
    }
    
    //MARK: Actions
    @IBAction func getDirections(_ sender: UIBarButtonItem) {
        let testURL = URL(string: "comgooglemaps://")!
        var location: CLLocationCoordinate2D
        
        let alertController = UIAlertController(
            title: "Error",
            message: "You must select a marker to get directions.",
            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: nil))
        
        if survey?.fences?.count == 1 {
            let fence = survey?.fences?.anyObject() as! Fence
            let coordinates = CLLocationCoordinate2D(latitude: fence.latitude, longitude: fence.longitude)
            location = coordinates
        } else {
            guard let selected = selectedLocation else {
                self.present(alertController, animated: true, completion: nil)
                return
            }
            location = selected
        }
        
        // trys to open Google Maps otherwise defaults to Apple Maps
        if UIApplication.shared.canOpenURL(testURL) {
            let directionRequest = "comgooglemaps://?saddr=&daddr=\(location.latitude),\(location.longitude)&directionsmode=driving"
            let directionsURL = URL(string: directionRequest)!
            UIApplication.shared.open(directionsURL, options: [:], completionHandler: nil)
        } else {
            //let coordinate = CLLocationCoordinate2DMake(currentSurvey.latitude,currentSurvey.longitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location, addressDictionary:nil))
            mapItem.name = "Survey"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    //MARK: Location manager methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = manager.location!.coordinate // convert user's location to CLLocationCoordinate2D
        let inset = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100) // area around the two bounds
        
        guard let coordinates = surveyLocation else {
            print("Could not load Google Maps API because location is not available.")
            
            return
        }
        
        let bounds = GMSCoordinateBounds(coordinate: coordinates, coordinate: currentLocation)
        let camera = mapView.camera(for: bounds, insets: inset)
        mapView.camera = camera!
        mapView.isMyLocationEnabled = true
        locationManager.stopUpdatingLocation()
    }
}

extension GoogleMapsViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        selectedLocation = marker.position
        return false
    }
}
