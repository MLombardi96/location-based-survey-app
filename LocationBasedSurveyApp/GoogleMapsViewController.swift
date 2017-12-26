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
        // CLLocationManager initialization
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        // set the survey locaiton when the view loads
        if survey != nil {
            surveyLocation = CLLocationCoordinate2D(latitude: survey!.latitude, longitude: survey!.longitude)
        } else {
            fatalError("No existing survey available to map.")
        }
        
        // default camera position and initialization of mapView
        let camera = GMSCameraPosition.camera(withTarget: surveyLocation!, zoom: 15.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView
    
        // survey location marker
        let surveyMarker = GMSMarker()
        surveyMarker.position = surveyLocation!
        surveyMarker.title = survey!.name
        surveyMarker.map = mapView
    }
    
    //MARK: Actions
    /****
     * When pressed attempts to open Google Maps, if not available opens Apple Maps.
     * !!!Haven't tested on an actual phone with Google Maps installed!!!
     ****/
    @IBAction func getDirections(_ sender: UIBarButtonItem) {
        let testURL = URL(string: "comgooglemaps-x-callback://")!
        if UIApplication.shared.canOpenURL(testURL) {
            let directionRequest = "comgooglemaps-x-callback://" +
                "?center=\(survey!.latitude),\(survey!.longitude)&zoom=15&iew=transit"
            let directionsURL = URL(string: directionRequest)!
            UIApplication.shared.canOpenURL(directionsURL)
        } else {
            //NSLog("Can't use comgoogleaps-x-callback:// on this device.")
            let coordinate = CLLocationCoordinate2DMake(survey!.latitude,survey!.longitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            mapItem.name = "\(survey!.name) Survey"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    /****
     * Constantly maintains the user's current location. This function allows the user's and the
     * the survey's location to be on screen at the same time.
     ****/
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = manager.location!.coordinate // convert user's location to CLLocationCoordinate2D
        let inset = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50) // area around the two bounds
        
        let bounds = GMSCoordinateBounds(coordinate: surveyLocation!, coordinate: currentLocation)
        let camera = mapView.camera(for: bounds, insets: inset)
        mapView.camera = camera!
        mapView.isMyLocationEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
