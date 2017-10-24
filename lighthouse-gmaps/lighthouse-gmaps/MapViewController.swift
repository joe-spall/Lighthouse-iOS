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

    @IBOutlet var mapView:GMSMapView!
    
    let CRIME_PULL_URL:String = "https://www.app-lighthouse.com/app/crimepullcirc.php"
    
    private var clusterManager: GMUClusterManager!
    
    let locationManager = CLLocationManager()
    var lastLocation = CLLocation()
    let CRIME_ICON:UIImage = UIImage(named:"crime_icon")!
    var storedCrimes:[Crime] = []
    var currentCrimeEntryString:String = ""
    var currentDangerLevel:String = ""
    var crimeInfoTotal: UIScrollView?
    var pullCounter = 0
    
    //Auto Complete
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // Set up the cluster manager with default icon generator and renderer.
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        renderer.delegate = self
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)

        // Register self to listen to both GMUClusterManagerDelegate and GMSMapViewDelegate events.
        
       
        
        mapView.delegate = self
        mapView.isIndoorEnabled = false
        clusterManager.setDelegate(self, mapDelegate: self)
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        let subView = UIView(frame: CGRect(x: 0, y: 20.0, width: 350.0, height: 45.0))
        
        subView.addSubview((searchController?.searchBar)!)
        //view.addSubview(subView)
        searchController?.searchBar.sizeToFit()
        searchController?.hidesNavigationBarDuringPresentation = false
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the navigation bar on this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
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
                            //TODO Make error more effective
                            print(error)
                            self.createErrorAlert(description: error.localizedDescription)
                        }
                    }
                    self.addCrimesToMap(crimeArray: self.storedCrimes)
                    
                    //self.calculateDanger(crimes: self.storedCrimes,userLoc: userLocation)
                }
                else{
                    //TODO Make error more effective
                    print(mightError.string!)
                    self.createErrorAlert(description: mightError.string!)
                }
                
            }
            else {
                //TODO Make error more effective
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
    
    func makeCrimeInfoView(viewCollection: [CrimeInfoView],crimeX:CGFloat,crimeY:CGFloat) -> UIScrollView{
        //TODO Make the weight calculation dynamic
        var maxWidth:CGFloat = 0.0
        var maxHeight:CGFloat = 0.0
        for singleView in viewCollection{
            if maxWidth < singleView.frame.width{
                maxWidth = singleView.frame.width
            }
            
            if maxHeight < singleView.frame.height{
                maxHeight = singleView.frame.height
            }
        }
        if maxWidth == 0{
            maxWidth = 227
        }
        
        if maxHeight == 0{
            maxHeight = 66
        }
        //TODO-END
        
        //TODO Possibly translate into a custom class
        let stackView = UIStackView(arrangedSubviews: viewCollection.reversed())
        stackView.axis = UILayoutConstraintAxis.vertical
        stackView.distribution  = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.center
        stackView.spacing = 3.0
        stackView.frame = CGRect(x: 0, y: 0, width: maxWidth, height: maxHeight*CGFloat(viewCollection.count))
        
        var scrollView = UIScrollView()
        
        if(viewCollection.count > 3){
            scrollView = UIScrollView(frame: CGRect(x: crimeX - (maxWidth/2), y: crimeY - (CGFloat(4)*maxHeight), width: maxWidth, height: maxHeight*CGFloat(3)-(maxHeight/3)))
        }
        else{
            scrollView = UIScrollView(frame: CGRect(x: crimeX - (maxWidth/2), y: crimeY - (CGFloat(viewCollection.count+1) * maxHeight), width: maxWidth, height: CGFloat(viewCollection.count)*maxHeight))
        }
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor(red:0/255.0, green:0/255.0, blue:0/255.0, alpha: 1.0).cgColor
        scrollView.layer.cornerRadius = 10
        scrollView.contentSize = stackView.bounds.size
        scrollView.backgroundColor = UIColor(red:1, green:1, blue:1, alpha: 0.5)
        scrollView.addSubview(stackView)
        scrollView.tag = 100
        scrollView.alpha = 0
        return scrollView
    }
    
    func makePopupForSingleCrime(crimeItem:CrimeClusterItem){
        let singleCrimeInfoView:CrimeInfoView = CrimeInfoView()
        let currentCrime:Crime = crimeItem.crime
        singleCrimeInfoView.setAllCrimeInfo(currentCrime: currentCrime)
       
        let infoViewCollection:[CrimeInfoView] = [singleCrimeInfoView]
        let crimePoint = mapView.projection.point(for: currentCrime.location)
        
        crimeInfoTotal = makeCrimeInfoView(viewCollection: infoViewCollection, crimeX: crimePoint.x, crimeY: crimePoint.y)
        mapView.addSubview(crimeInfoTotal!)        
    }
    
    func makePopupForCluster(crimeCluster:GMUCluster){
        var infoViewCollection:[CrimeInfoView] = []
        let clusterItems = crimeCluster.items
        for singleCrimeItem in clusterItems{
            let crime = (singleCrimeItem as! CrimeClusterItem).crime
            let singleCrimeInfoView:CrimeInfoView = CrimeInfoView()
            singleCrimeInfoView.setAllCrimeInfo(currentCrime: crime!)
            infoViewCollection.append(singleCrimeInfoView)
        }
        
        let crimePoint = mapView.projection.point(for: crimeCluster.position)

        crimeInfoTotal = makeCrimeInfoView(viewCollection: infoViewCollection, crimeX: crimePoint.x, crimeY: crimePoint.y)
        mapView.addSubview(crimeInfoTotal!)
        
    }
    
    func showPopup(_ shouldShow: Bool, animated: Bool) {
        let alpha: CGFloat = (shouldShow ? 1 : 0)
        if animated {
            UIView.animate(withDuration: 0.25,animations: { [unowned self] in
                self.crimeInfoTotal?.alpha = alpha
                }, completion: { (finished: Bool) in
                    if(!shouldShow){
                        if let viewWithTag = self.view.viewWithTag(100) {
                            viewWithTag.removeFromSuperview()
                        }
                        self.crimeInfoTotal = nil
                    }
            })
        } else {
            crimeInfoTotal?.alpha = alpha
            if(!shouldShow){
                if let viewWithTag = self.view.viewWithTag(100) {
                    viewWithTag.removeFromSuperview()
                }
                self.crimeInfoTotal = nil
            }
        }
    }


    //Error Handling
    
    func createErrorAlert(description:String){
        let alert = UIAlertController(title: "Alert", message: description, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - GMUClusterManagerDelegate
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool {
        let currentZoom = mapView.camera.zoom
        if(currentZoom <= 20){
            let newCamera = GMSCameraPosition.camera(withTarget: cluster.position, zoom: mapView.camera.zoom + 1)
            let update = GMSCameraUpdate.setCamera(newCamera)
            mapView.moveCamera(update)
        }
        else{
            makePopupForCluster(crimeCluster: cluster)
        }
        return false
    }
    
    func clusterManager(_ clusterManager: GMUClusterManager, didTap clusterItem: GMUClusterItem) -> Bool {
        makePopupForSingleCrime(crimeItem: clusterItem as! CrimeClusterItem)
        return false
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture {
            showPopup(false, animated: true)
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if crimeInfoTotal != nil{
            let userViewPosition = mapView.projection.point(for: position.target)
            crimeInfoTotal?.frame.origin.x = userViewPosition.x - (crimeInfoTotal?.frame.width)!/2
            //TODOOOOOO RELATED TO CLUSTER ICON SIZE
            crimeInfoTotal?.frame.origin.y = userViewPosition.y - (crimeInfoTotal?.frame.height)! - 20
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
        //TODO Make Error more effective
        print("Error \(error)")
    }
}

// Handle the user's selection.
extension MapViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
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

class CrimeClusterItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    var crime: Crime!
    
    init(crime: Crime) {
        self.position = crime.location
        self.crime = crime
    }
}


