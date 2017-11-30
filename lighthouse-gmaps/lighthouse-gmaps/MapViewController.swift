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

class MapViewController: UIViewController, GMUClusterManagerDelegate, GMSMapViewDelegate, GMUClusterRendererDelegate,UISearchControllerDelegate{

    // MARK: - Mapping
    @IBOutlet var mapView:GMSMapView!
    let locationManager = CLLocationManager()
    var lastLocation = CLLocation()
    let MAP_STYLE_TYPE_OPTIONS = [GMSMapViewType.normal, GMSMapViewType.hybrid, GMSMapViewType.satellite, GMSMapViewType.terrain]
    let MAP_STYLE_NAME_OPTIONS:[String] = ["Normal","Hybrid","Satellite","Terrain"]
    
    // MARK: - Data Pull
    let CRIME_PULL_URL:String = "http://app-lighthouse.herokuapp.com/api/"
    let URL_ROUTE:String = "route_crimepull"
    let URL_POINT:String = "point_crimepull"
    var storedCrimes:[Crime] = []
    var searchCicle:GMSCircle?
    
    // MARK: - Danger Level
    var currentDanger:Double = 0
    
    // MARK: - Cluster
    private var clusterManager: GMUClusterManager!
    let CRIME_ICON:UIImage = UIImage(named:"crime_icon")!
    
    // MARK: - Popup window
    var crimeInfoSummary: CrimeInfoSummaryView?
    fileprivate var locationMarker : GMSMarker? = GMSMarker()
    
    // MARK: - Search
    var destResultsViewController: GMSAutocompleteResultsViewController?
    var destSearchController: UISearchController?
    let GOOGLE_DIRECTION_API:String = "AIzaSyAYo8bhVOYfriZCk-8i5fzpII_WRLJjS40"
    var placesClient: GMSPlacesClient!
    
    // MARK: - Routing
    var currentRoute:Route?
    let ROUTE_COLOR:[Int] = [0x28BF00, 0x53C300,0x7FC700,0xAECB00,0xCFC100,0xD49800,0xD86D00,0xDC40000,0xE01100,0xE5001F]
    var routeBounds:GMSCoordinateBounds = GMSCoordinateBounds()
    var startMarker:GMSMarker = GMSMarker()
    var endMarker:GMSMarker = GMSMarker()
    var polylineArray:[GMSPolyline] = []
    
    // MARK: - Terms and Conditions
    var comingFromTerms:Bool = false;
    
    // MARK: - Lighthouse Button
    @IBOutlet var lighthouseButton:UIButton!
    var currentMenuView:UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(!isKeyPresentInUserDefaults(key: "terms_conditions")){
           sendToTermsView()
        }
        else{
            initMapViewController()
        }
        
    }
    
    func initMapViewController(){
        // MARK: - Lighthouse Button
        view.bringSubview(toFront: self.lighthouseButton)
        
        // MARK: - Mapping
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
        mapView.isIndoorEnabled = false
        mapView.mapType = MAP_STYLE_TYPE_OPTIONS[MAP_STYLE_NAME_OPTIONS.index(of: UserDefaults.standard.string(forKey: "map_style")!)!]
        
        // MARK: - Cluster
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = MapClusterRender(mapView: mapView, clusterIconGenerator: iconGenerator)
        renderer.delegate = self
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        clusterManager.setDelegate(self, mapDelegate: self)
        
        
        // MARK: - Search
        destResultsViewController = GMSAutocompleteResultsViewController()
        destResultsViewController?.delegate = self
        
        destSearchController = UISearchController(searchResultsController: destResultsViewController)
        destSearchController?.searchResultsUpdater = destResultsViewController
        destSearchController?.delegate = self
        
        // Put the search bar in the navigation bar.
        destSearchController?.searchBar.sizeToFit()
        navigationItem.titleView = destSearchController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        destSearchController?.hidesNavigationBarDuringPresentation = false

        // Places stuff
        placesClient = GMSPlacesClient.shared()
       // placeAutocomplete()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)

        // Hide the navigation bar on this view controller
        mapView.mapType = MAP_STYLE_TYPE_OPTIONS[MAP_STYLE_NAME_OPTIONS.index(of: UserDefaults.standard.string(forKey: "map_style")!)!]
    
        if(comingFromTerms){
            initMapViewController()
            comingFromTerms = false
        }
        
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show the navigation bar on other view controllers
        
    }
    
    func drawSearchCircle(userLocation: CLLocationCoordinate2D){
        let radius = Double(UserDefaults.standard.integer(forKey:"radius"))*0.3048
        searchCicle = GMSCircle(position: userLocation, radius: radius)
        // TODO: Make based on crime levels instead of random
        let color = ROUTE_COLOR[Int(arc4random_uniform(UInt32(ROUTE_COLOR.count)))]
        searchCicle?.strokeColor = UIColor(rgb:color)
        searchCicle?.strokeWidth = 4
        searchCicle?.fillColor = UIColor(rgb:color).withAlphaComponent(0.50)
        searchCicle!.map = mapView
    }
    
    func pullCrimesOnPoint(userLocation: CLLocationCoordinate2D){
        let currentLat:Double = ((userLocation.latitude)*1000000).rounded()/1000000
        let currentLong:Double = ((userLocation.longitude)*1000000).rounded()/1000000
        let radius = Double(UserDefaults.standard.integer(forKey:"radius"))*0.3048
        let year = UserDefaults.standard.string(forKey:"year")!
        let param:[String:Any] = [
            "lat": currentLat,
            "lng": currentLong,
            "radius": radius,
            "year": year]
        Alamofire.request(CRIME_PULL_URL + URL_POINT, method: .post, parameters: param).response{ response in
            let error = response.error?.localizedDescription
            if(error == nil) {
                let dataFromPull = response.data!
                let json = JSON(data:dataFromPull)
                let mightError = json["error"]
                //TODO: Improve storage
                self.storedCrimes = []
                if(mightError == JSON.null){
                    let resultArray = json.array!
                    for subJson:JSON in resultArray {
                        do{
                            let id = subJson["_id"].string
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
                    self.calculateDanger(crimes: self.storedCrimes,userLoc: userLocation)
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
    
    func pullCrimesRoute(route: Route){
        var points:[Double] = []
        let steps = route.steps
        if(steps.count > 0){
            let startLat = steps[0].startLocationStep.latitude
            let startLng = steps[0].startLocationStep.longitude
            points.append(startLat)
            points.append(startLng)
        }
        for step in steps{
            let endLat = step.endLocationStep.latitude
            let endLng = step.endLocationStep.longitude
            points.append(endLat)
            points.append(endLng)
        }
        let radius = Double(UserDefaults.standard.integer(forKey:"radius"))*0.3048
        let year = UserDefaults.standard.string(forKey:"year")!
        let param:[String:Any] = [
            "points": points,
            "radius": radius,
            "year": year]
        Alamofire.request(CRIME_PULL_URL + URL_ROUTE, method: .post, parameters: param).response{ response in
            let error = response.error?.localizedDescription
            if(error == nil) {
                let dataFromPull = response.data!
                let json = JSON(data:dataFromPull)
                let mightError = json["error"]
                //TODO: Improve storage
                self.storedCrimes = []
                if(mightError == JSON.null){
                    let resultArray = json.array!
                    for subJson:JSON in resultArray {
                        do{
                            let id = subJson["_id"].string
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
                    self.changeMapForRoute(route: route)
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
    
    func calculateDanger(crimes: [Crime], userLoc: CLLocationCoordinate2D){
        let currentDate = Date()
        for crime in crimes{
            let userDefinedDanger = UserDefaults.standard.double(forKey: crime.type)
            currentDanger += crime.calculateSingleThreatScore(userLocation: userLoc, currentDate: currentDate, userValue: userDefinedDanger)
        }
        currentDanger /= Double(crimes.count)
    }
    
    func addCrimesToMap(crimeArray: [Crime]){
        mapView.clear()
        clusterManager.clearItems()
        for crime in crimeArray{
            let item = CrimeClusterItem(crime: crime)
            clusterManager.add(item)
        }
        clusterManager.cluster()
        drawSearchCircle(userLocation: lastLocation.coordinate)

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
    
    func placeAutocomplete() {
        let filter = GMSAutocompleteFilter()
        filter.type = .noFilter
        placesClient.autocompleteQuery("Sydney Oper", bounds: nil, filter: filter, callback: {(results, error) -> Void in
            if let error = error {
                print("Autocomplete error \(error)")
                return
            }
            if let results = results {
                for result in results {
                    print("Result \(result.attributedFullText) with placeID \(String(describing: result.placeID))")
                }
            }
        })
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
                        self.pullCrimesRoute(route: newRoute)
                        
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
        startMarker.map = nil
        endMarker.map = nil
        removeAllPolylineElements(polySteps: polylineArray)
        
        routeBounds = GMSCoordinateBounds(coordinate: route.startLocation, coordinate: route.endLocation)
        startMarker = GMSMarker(position: route.startLocation)
        endMarker = GMSMarker(position: route.endLocation)
        
        startMarker.map = mapView
        endMarker.map = mapView
        addAllStepElements(routeSteps: route.steps)
        
        // Camera update
        let update = GMSCameraUpdate.fit(routeBounds, with: UIEdgeInsets(top: 150, left: 40, bottom: 50, right: 40))
        mapView.moveCamera(update)
        
    }
    
    @IBAction func makeQuickMenu(){
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        let viewHeight = screenHeight/3;
        
        let testFrame: CGRect = CGRect(x: 0, y: screenHeight-viewHeight, width: screenWidth, height: viewHeight)
        currentMenuView = UIView(frame: testFrame)
        let button = UIButton() // let preferred over var here
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        button.setTitle("Close", for: UIControlState.normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        currentMenuView?.addSubview(button)
        currentMenuView?.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        self.view.addSubview((currentMenuView)!)
        self.view.bringSubview(toFront: (currentMenuView)!)
        
    }
    
    @objc func buttonAction(sender: UIButton!) {
        currentMenuView?.removeFromSuperview()
    }
    
    func addAllStepElements(routeSteps:[RouteStep]){
        polylineArray = []
        for step in routeSteps{
            let curPoly = GMSPolyline(path: GMSPath(fromEncodedPath: step.polylinePath))
            curPoly.strokeWidth = 5
            //TODO: DON'T Make Random
            curPoly.strokeColor = UIColor(rgb:ROUTE_COLOR[Int(arc4random_uniform(UInt32(ROUTE_COLOR.count)))])
            curPoly.map = mapView
            polylineArray.append(curPoly)
        }

    }
    
    func removeAllPolylineElements(polySteps:[GMSPolyline]){
        for step in polySteps{
            step.map = nil
        }
    }
    
    func sendToTermsView(){
        let transition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionMoveIn
        transition.subtype = kCATransitionFromTop
        navigationController?.view.layer.add(transition, forKey: nil)
        comingFromTerms = true;
        let viewController:InitialLoadViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InitialLoadViewController") as! InitialLoadViewController
        self.navigationController?.pushViewController(viewController, animated: false)
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
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
        if status == .denied{
            //TODO: Implement if access denied, question whether to use the app without location access
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            if location.coordinate.latitude != lastLocation.coordinate.latitude && location.coordinate.longitude != lastLocation.coordinate.longitude
            {
                lastLocation = location
                mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
                locationManager.stopUpdatingLocation()
                pullCrimesOnPoint(userLocation: location.coordinate)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        //TODO: Make Error more effective
        print("Error \(error)")
    }
}


extension MapViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        // Do something with the selected place.
        destSearchController?.isActive = false
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

