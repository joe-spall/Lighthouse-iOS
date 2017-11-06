//
//  ViewController.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 10/7/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Alamofire
import SwiftyJSON

class MapViewController: UIViewController, GMUClusterManagerDelegate, GMSMapViewDelegate, GMUClusterRendererDelegate{

    // MARK: - Mapping
    @IBOutlet var mapView:GMSMapView!
    let locationManager = CLLocationManager()
    var lastLocation = CLLocation()
    
    // MARK: - Data Pull
    let CRIME_PULL_URL:String = "https://www.app-lighthouse.com/app/crimepullcirc.php"
    var storedCrimes:[Crime] = []
    
    // MARK: - Cluster
    private var clusterManager: GMUClusterManager!
    let CRIME_ICON:UIImage = UIImage(named:"crime_icon")!
    
    // MARK: - Popup window
    var crimeInfoSummary: CrimeInfoSummaryView?
    fileprivate var locationMarker : GMSMarker? = GMSMarker()
    
    // MARK: - Search
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    let GOOGLE_DIRECTION_API:String = "AIzaSyAYo8bhVOYfriZCk-8i5fzpII_WRLJjS40"
    
    // MARK: - Routing
    var currentRoute:Route?
    let ROUTE_COLOR:[Int] = [0x28BF00, 0x53C300,0x7FC700,0xAECB00,0xCFC100,0xD49800,0xD86D00,0xDC40000,0xE01100,0xE5001F]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - Mapping
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        mapView.isIndoorEnabled = false
        
        // MARK: - Cluster
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        renderer.delegate = self
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        clusterManager.setDelegate(self, mapDelegate: self)
        
        
        
        
        // MARK: - Search
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Put the search bar in the navigation bar.
        searchController?.searchBar.sizeToFit()
        navigationItem.titleView = searchController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on this view controller
       // self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        
    }
    
    func drawSearchCircle(userLocation: CLLocationCoordinate2D){
        let radius = Double(UserDefaults.standard.integer(forKey:"radius"))*0.3048
        let circ = GMSCircle(position: userLocation, radius: radius)
        circ.map = mapView
    }
    
    func pullCrimes(userLocation: CLLocationCoordinate2D){
        let currentLat:Double = ((userLocation.latitude)*1000000).rounded()/1000000
        let currentLong:Double = ((userLocation.longitude)*1000000).rounded()/1000000
        let radius = Double(UserDefaults.standard.integer(forKey:"radius"))/364000
        let year = UserDefaults.standard.string(forKey:"year")!
        let param:[String:Any] = [
            "curlatitude": currentLat,
            "curlongitude": currentLong,
            "radius": radius,
            "year": year]
        Alamofire.request(CRIME_PULL_URL, method: .post, parameters: param).response{ response in
            let error = response.error?.localizedDescription
            if(error == nil) {
                let dataFromPull = response.data!
                let json = JSON(data:dataFromPull)
                let mightError = json["error"]
                if(mightError == JSON.null){
                    let resultsArray = json["results"]
                    for (_,subJson):(String, JSON) in resultsArray {
                        do{
                            let id = subJson["id"].string
                            if !self.storedCrimes.contains(where: {$0.id == id}){
                                try self.storedCrimes.append(Crime(json: subJson))
                            }
                        }
                        catch{
                            //TODO: Make error more effective
                            print(error)
                            self.createErrorAlert(description: error.localizedDescription)
                        }
                    }
                    self.addCrimesToMap(crimeArray: self.storedCrimes)
                    
                    //self.calculateDanger(crimes: self.storedCrimes,userLoc: userLocation)
                }
                else{
                    //TODO: Make error more effective
                    print(mightError.string!)
                    self.createErrorAlert(description: mightError.string!)
                }
                
            }
            else {
                //TODO: Make error more effective
                print(error!)
                self.createErrorAlert(description: error!)
            }
        }
        
    }
    
    func addCrimesToMap(crimeArray: [Crime]){
        mapView.clear()
        for crime in crimeArray{
            let item = CrimeClusterItem(crime: crime)
            clusterManager.add(item)
        }
        clusterManager.cluster()
    }
    
    func showPopup(_ shouldShow: Bool, animated: Bool) {
        let alpha: CGFloat = (shouldShow ? 1 : 0)
        if animated {
            UIView.animate(withDuration: 0.25,animations: { [unowned self] in
                self.crimeInfoSummary?.alpha = alpha
                }, completion: { (finished: Bool) in
                    if(!shouldShow){
                        self.crimeInfoSummary?.removeFromSuperview()
                        self.crimeInfoSummary = nil
                    }
            })
        } else {
            crimeInfoSummary?.alpha = alpha
            if(!shouldShow){
                self.crimeInfoSummary?.removeFromSuperview()
                self.crimeInfoSummary = nil
            }
        }
    }
    
    
    
    // MARK: - Routing
    func getDirections(destination:CLLocationCoordinate2D){
        let originString = locationToString(location: lastLocation.coordinate)
        let destinationString = locationToString(location: destination)
        Alamofire.request("https://maps.googleapis.com/maps/api/directions/json?" +
            "origin=" + originString +
            "&destination=" + destinationString +
            "&mode=" + "walking" +
            "&key=" + GOOGLE_DIRECTION_API).responseJSON
        { response in
                if response.response?.statusCode == 200{
                    do{
                        let json = JSON(response.result.value!)
                        let newRoute = try Route(json: json["routes"][0])
                        self.currentRoute = newRoute
                        self.changeMapForRoute(route: self.currentRoute!)
                    }
                    catch{
                        //TODO: Make error more effective
                        print(error)
                        self.createErrorAlert(description: error.localizedDescription)
                    }
                }
        }
        
    }

    func locationToString(location:CLLocationCoordinate2D) -> String{
        var output:String = ""
        output += String(format: "%f",location.latitude)
        output += ","
        output += String(format: "%f",location.longitude)
        return output
    }

    func changeMapForRoute(route:Route){
        let startMarker = GMSMarker(position: route.startLocation)
        let endMarker = GMSMarker(position: route.endLocation)
        let polyline = GMSPolyline(path: GMSPath(fromEncodedPath: route.polylinePath))
        polyline.strokeWidth = 5
        polyline.strokeColor = UIColor(rgb:0x33cc33)
        startMarker.map = mapView
        endMarker.map = mapView
        polyline.map = mapView
        
    }
    


    // MARK: - Error Handling
    
    func createErrorAlert(description:String){
        let alert = UIAlertController(title: "Alert", message: description, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - GMUClusterManagerDelegate
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool {
        if(crimeInfoSummary != nil)
        {
            showPopup(false, animated: false)
        }
        let currentZoom = mapView.camera.zoom
        if(currentZoom <= 20){
            let newCamera = GMSCameraPosition.camera(withTarget: cluster.position, zoom: mapView.camera.zoom + 1)
            let update = GMSCameraUpdate.setCamera(newCamera)
            mapView.moveCamera(update)
        }
        else{
            if crimeInfoSummary == nil{
                crimeInfoSummary = CrimeInfoSummaryView()
            }
            
            crimeInfoSummary?.makeViewForCluster(crimeCluster: cluster)
            mapView.addSubview(crimeInfoSummary!)
        }
        return false
    }
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        if(crimeInfoSummary != nil)
        {
            showPopup(false, animated: false)
        }
        if crimeInfoSummary == nil{
            crimeInfoSummary = CrimeInfoSummaryView()
        }
        
        crimeInfoSummary?.makeViewForSingle(crimeItem: clusterItem as! CrimeClusterItem)
        mapView.addSubview(crimeInfoSummary!)

        
        return false
    }
    
    //MARK: - GMSMapViewDelegate
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        if gesture {
            showPopup(false, animated: true)
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        if crimeInfoSummary != nil{
            let userViewPosition = mapView.projection.point(for: position.target)
            crimeInfoSummary?.frame.origin.x = userViewPosition.x - (crimeInfoSummary?.frame.width)!/2
            if crimeInfoSummary?.numberOfCrimes() == 1 {
                
                crimeInfoSummary?.frame.origin.y = userViewPosition.y - (crimeInfoSummary?.frame.height)! - 55
            }
            else{
               crimeInfoSummary?.frame.origin.y = userViewPosition.y - (crimeInfoSummary?.frame.height)! - 25
            }

            showPopup(true, animated: true)
            
        }
    }
    
    // MARK: - GMUClusterRendererDelagate
    func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker) {
        if (marker.userData as? CrimeClusterItem) != nil {
            marker.icon = CRIME_ICON
        }
    }
    
}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            if location.coordinate.latitude != lastLocation.coordinate.latitude && location.coordinate.longitude != lastLocation.coordinate.longitude
            {
                lastLocation = location
                mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
                locationManager.stopUpdatingLocation()
                pullCrimes(userLocation: location.coordinate)
                drawSearchCircle(userLocation: location.coordinate)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        //TODO: Make Error more effective
        print("Error \(error)")
    }
}


//// Handle the user's selection.
extension MapViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        // Do something with the selected place.
//        print("Place name: \(place.name)")
//        print("Place address: \(String(describing: place.formattedAddress))")
//        print("Place attributions: \(String(describing: place.attributions))")
//        print("Place coordinates: \(place.coordinate)")
        getDirections(destination: place.coordinate)
        
    }

    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }

    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func didUpdateAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}


// MARK: - CrimeClusterItem

class CrimeClusterItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    var crime: Crime!
    
    init(crime: Crime) {
        self.position = crime.location
        self.crime = crime
    }
}


// MARK: - UIColor
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

