//
//  ViewController.swift
//  GMapsDemo
//
//  Created by Gabriel Theodoropoulos on 29/3/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

import UIKit
import SystemConfiguration


enum TravelModes: Int {
    case driving
    case walking
    case bicycling
}


class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    @IBOutlet weak var viewMap: GMSMapView!
    
    @IBOutlet weak var lblInfo: UILabel!
    
    
    var locationManager = CLLocationManager()
    
    var didFindMyLocation = false
    
    var locationMarker: GMSMarker!
    
    var originMarker: GMSMarker!
    
    var destinationMarker: GMSMarker!
    
    var travelMode = TravelModes.walking
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 48.857165, longitude: 2.354613, zoom: 8.0)
        // Create a rectangular path

        viewMap.camera = camera
        viewMap.delegate = self
        
        viewMap.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
        
        let newYorkMurder = Crime(type: "Murder", date: "2014-01-01",time: "00:00:00", lat:40.85919, long:-73.90068)
        
        addCrimeToMap(curCrime: newYorkMurder)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            viewMap.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 15.0)
            viewMap.settings.myLocationButton = true
            
            didFindMyLocation = true
        }
    }
    
       
    
    // MARK: IBAction method implementation
    
    @IBAction func changeMapType(_ sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Map Types", message: "Select map type:", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let normalMapTypeAction = UIAlertAction(title: "Normal", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.viewMap.mapType = GMSMapViewType.normal
        }
        
        let terrainMapTypeAction = UIAlertAction(title: "Terrain", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.viewMap.mapType = GMSMapViewType.terrain
        }
        
        let hybridMapTypeAction = UIAlertAction(title: "Hybrid", style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.viewMap.mapType = GMSMapViewType.hybrid
        }
        
        let cancelAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
        }
        
        actionSheet.addAction(normalMapTypeAction)
        actionSheet.addAction(terrainMapTypeAction)
        actionSheet.addAction(hybridMapTypeAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    func addCrimeToMap(curCrime:Crime){
        
        let position = CLLocationCoordinate2D(latitude: curCrime.latitude, longitude: curCrime.longitude)
        let crimeMarker = GMSMarker(position: position)
        crimeMarker.icon = UIImage(named: "crimeLoc")
        crimeMarker.infoWindowAnchor = CGPoint(x: 0.5, y:-0.2)
        crimeMarker.userData = curCrime
        crimeMarker.map = viewMap
        
        
    }
    
    
    
    
    // MARK: CLLocationManagerDelegate method implementation
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            viewMap.isMyLocationEnabled = true
        }
    }
    
    
    // MARK: Custom method implementation
    
    func showAlertWithMessage(_ message: String) {
        let alertController = UIAlertController(title: "GMapsDemo", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let closeAction = UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            
        }
        
        alertController.addAction(closeAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    func setupLocationMarker(_ coordinate: CLLocationCoordinate2D) {
        if locationMarker != nil {
            locationMarker.map = nil
        }
        
        locationMarker = GMSMarker(position: coordinate)
        locationMarker.map = viewMap
        
        locationMarker.appearAnimation = GMSMarkerAnimation.pop
        locationMarker.icon = UIImage(named: "destLoc")
        locationMarker.opacity = 0.75

        
    }
    
    
    
    
    // MARK: GMSMapViewDelegate method implementation
    
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        
        let window = UIView()
        
        if let crimeInfo = marker.userData as? Crime
        {
             let crimeWindow = Bundle.main.loadNibNamed("CrimeWindow", owner: self.view, options: nil)?.first! as! CrimeWindow

            
            crimeWindow.typeOfCrime.text = crimeInfo.typeOfCrime
            crimeWindow.dateOfCrime.text = crimeInfo.dateOfCrime
            crimeWindow.timeOfCrime.text = crimeInfo.timeOfCrime
            crimeWindow.layer.cornerRadius = 67.5
            crimeWindow.layer.masksToBounds = true
            crimeWindow.layer.borderColor = UIColor(red:245/255.0, green:21/255.0, blue:21/255.0, alpha: 1.0).cgColor
            crimeWindow.layer.borderWidth = 5.0
            return crimeWindow
        }
        return window
    }
    
    
        
    
}

