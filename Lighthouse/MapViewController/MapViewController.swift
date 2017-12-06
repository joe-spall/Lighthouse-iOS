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
import MBProgressHUD

class MapViewController: UIViewController, GMUClusterManagerDelegate, GMSMapViewDelegate, GMUClusterRendererDelegate,UISearchControllerDelegate{
    
    // MARK: - Screen Sizing
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    // MARK: - Settings Changed
    var settingsChanged: Bool = false
    
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
    let POINT_COLOR:[Int] = [0x28BF00,0xE6E600,0xE01100]
    let POINT_RANGES:[Double] = [0.00001,0.001]
    var searchCicle:GMSCircle?
    
    // MARK: - Danger Level
    var localDanger:Double = 0
    
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
    let ROUTE_COLOR:[Int] = [0x28BF00,0xE6E600,0xE01100]
    let ROUTE_DANGER_RANGES:[Double] = [0.00001,0.0005]
    let ROUTE_WIDTH:CGFloat = 5

    let UNDER_ROUTE_COLOR:Int = 0x000000
    let UNDER_ROUTE_WIDTH:CGFloat = 9
    
    let END_MARKER_COLOR:Int = 0xFF6600
    var endMarker:GMSMarker = GMSMarker()
    var polylineArray:[GMSPolyline] = []
    
    // MARK: - Terms and Conditions
    var comingFromTerms:Bool = false;
    
    // MARK: - Drawer
    @IBOutlet var lighthouseButton:UIButton!
    @IBOutlet weak var bottomContraint:NSLayoutConstraint!
    var clusterStates:[Bool] = [true,true,true,true,true]
    let CLUSTER_GROUP_NAMES:[String] = ["assault","car_theft","homicide","ped_theft","rape"]
    let DRAWER_COLOR:Int = 0x7f7f7f
    let STATE_BUTTON_NO_SELECT:Int = 0xCCCCCC
    let STATE_BUTTON_SELECT:Int = 0xFF751A
    let SETTINGS_COLOR:Int = 0x333333
    var currentDrawerView:UIView?
    var drawerOpen:Bool = false
    
    
    // MARK: - Safety View
    var safetyView:UILabel?
    
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

        // MARK: - Drawer
        for group in CLUSTER_GROUP_NAMES{
            clusterStates[CLUSTER_GROUP_NAMES.index(of: group)!] = UserDefaults.standard.bool(forKey: group+"_state")
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if(settingsChanged){
            mapView.mapType = MAP_STYLE_TYPE_OPTIONS[MAP_STYLE_NAME_OPTIONS.index(of: UserDefaults.standard.string(forKey: "map_style")!)!]
            if(lastLocation != CLLocation()){
                 pullCrimesOnPoint(userLocation: lastLocation.coordinate)
            }
        }
    
        if(comingFromTerms){
            initMapViewController()
            comingFromTerms = false
        }
        
    }
    
    func calculateLocalDanger(crimes: [Crime], userLoc: CLLocationCoordinate2D){
        let currentDate = Date()
        var tempDanger:Double = 0
        for crime in crimes{
            let userDefinedDanger = UserDefaults.standard.double(forKey: crime.type)
            tempDanger += crime.calculateSingleThreatScore(userLocation: userLoc, currentDate: currentDate, userValue: userDefinedDanger)
        }
        localDanger = tempDanger
        drawSearchCircle(userLocation: userLoc)
    }
    
    func drawSearchCircle(userLocation: CLLocationCoordinate2D){
        if(searchCicle != nil)
        {
            searchCicle!.map = nil
        }
        let radius = Double(UserDefaults.standard.integer(forKey:"radius"))*0.3048
        searchCicle = GMSCircle(position: userLocation, radius: radius)
        let color = calculateDangerColorPoint(radius: radius, dangerLevel: localDanger)
        searchCicle?.strokeColor = color
        searchCicle?.strokeWidth = 4
        searchCicle?.fillColor = color.withAlphaComponent(0.50)
        searchCicle!.map = mapView
        makeSafetyView(radius: radius)
        let cameraUpdate = GMSCameraUpdate.setTarget(userLocation, zoom: 18)
        mapView.animate(with: cameraUpdate)
    }
    
    func calculateDangerColorPoint(radius:Double, dangerLevel:Double) -> UIColor{
        let dangerPerSquareMeter = dangerLevel/(Double.pi*pow(radius,2.0))
        if(dangerPerSquareMeter <= POINT_RANGES[0]){
            return UIColor(rgb: POINT_COLOR[0])
        }
        else if(dangerPerSquareMeter <= POINT_RANGES[1]){
            return UIColor(rgb: POINT_COLOR[1])
        }
        else{
            return UIColor(rgb: POINT_COLOR[2])
        }
        
    }
    
    func pullCrimesOnPoint(userLocation: CLLocationCoordinate2D){
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.bezelView.color = UIColor.clear
        loadingNotification.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
        loadingNotification.backgroundView.style = MBProgressHUDBackgroundStyle.blur
        loadingNotification.label.text = "Loading"
       
        
        clearRoute(polySteps: polylineArray)
        
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
                    self.calculateLocalDanger(crimes: self.storedCrimes,userLoc: userLocation)
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
                else{
                    //TODO: Make error more effective
                    MBProgressHUD.hide(for: self.view, animated: true)
                    print(mightError.string!)
                    self.createErrorAlert(description: mightError.string!)
                }
                
            }
            else {
                //TODO: Make error more effective
                MBProgressHUD.hide(for: self.view, animated: true)
                print(error!)
                self.createErrorAlert(description: error!)
            }
        }

    }
    
    func pullCrimesRoute(route: Route){
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.bezelView.color = UIColor.clear
        loadingNotification.bezelView.style = MBProgressHUDBackgroundStyle.solidColor
        loadingNotification.backgroundView.style = MBProgressHUDBackgroundStyle.blur
        loadingNotification.label.text = "Loading"
        
        clearRoute(polySteps: polylineArray)
        
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
                    MBProgressHUD.hide(for: self.view, animated: true)

                }
                else{
                    MBProgressHUD.hide(for: self.view, animated: true)
                    //TODO: Make error more effective

                    print(mightError.string!)
                    self.createErrorAlert(description: mightError.string!)
                }
                
            }
            else {
                MBProgressHUD.hide(for: self.view, animated: true)

                //TODO: Make error more effective
                print(error!)
                self.createErrorAlert(description: error!)
            }
        }
        
    }
    
    func calcCrimeBounds(crimeArray:[Crime]) -> GMSCoordinateBounds{
        var minLat:Double = 0
        var maxLat:Double = 0
        var minLng:Double = 0
        var maxLng:Double = 0
        for crime in crimeArray{
            let currentLat = crime.location.latitude
            let currentLng = crime.location.longitude
            if(minLat == 0 || currentLat < minLat){
                minLat = currentLat
            }
            
            if(maxLat == 0 || currentLat > maxLat){
                maxLat = currentLat
            }
            
            if(minLng == 0 || currentLng < minLng){
                minLng = currentLng
            }
            
            if(maxLng == 0 || currentLng > maxLng){
                maxLng = currentLng
            }
            
        }
        let point1 = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLng)
        let point2 = CLLocationCoordinate2D(latitude: minLat, longitude: minLng)
        return GMSCoordinateBounds(coordinate: point1, coordinate: point2)
    }
    
    func addCrimesToMap(crimeArray: [Crime]){
        clusterManager.clearItems()
        for crime in crimeArray{
            if let i = CLUSTER_GROUP_NAMES.index(where: { $0.hasPrefix(crime.tag[0]) }) {
                if(clusterStates[i]){
                    let item = CrimeClusterItem(crime: crime)
                    clusterManager.add(item)
                }

            }
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
        endMarker.map = nil
        clearRoute(polySteps: polylineArray)
        
        // Camera update
        let update = GMSCameraUpdate.fit(route.bounds, with: UIEdgeInsets(top: 150, left: 40, bottom: 100, right: 40))
        mapView.moveCamera(update)
        
        
        endMarker = GMSMarker(position: route.endLocation)
        endMarker.iconView = changeLocationMarkerColor(color: UIColor(rgb:END_MARKER_COLOR))
        endMarker.map = mapView
        addAllStepElements(routeSteps: route.steps)
        
        
    }
    
    func changeLocationMarkerColor(color: UIColor) -> UIImageView{
        let marker = UIImage(named: "map_marker")!.withRenderingMode(.alwaysTemplate)
        let markerView = UIImageView(image: marker)
        markerView.tintColor = color
        return markerView
    }
    
    func makeSafetyView(radius:Double){
        safetyView?.removeFromSuperview()
        
        let viewHeight = screenHeight/12;
        let navigationBarHeight: CGFloat = self.navigationController!.navigationBar.frame.height
        safetyView = UILabel(frame: CGRect(x: screenWidth-viewHeight-20, y: navigationBarHeight+viewHeight/2,width: viewHeight, height:  viewHeight))
        safetyView?.font = UIFont.systemFont(ofSize: 20.0)
        
        let dangerPerSquareMeter = localDanger/(Double.pi*pow(radius,2.0))
        var fractionDanger = (dangerPerSquareMeter/POINT_RANGES.last!)*10
        var colorNumber = 0
        if(fractionDanger > 10){
            fractionDanger = 10
        }
        safetyView?.text = String(format: "%.1f", fractionDanger)
        
        if(fractionDanger < 2){
            colorNumber = ROUTE_COLOR[0]
        }
        else if(fractionDanger >= 2 && fractionDanger < 7){
            colorNumber = ROUTE_COLOR[1]
        }
        else{
            colorNumber = ROUTE_COLOR[2]
        }
        let color:UIColor = UIColor(rgb: colorNumber)
        safetyView?.textColor = color
        safetyView?.layer.borderColor = color.cgColor
        
        safetyView?.layer.borderWidth = 3.0
        safetyView?.textAlignment = .center
        safetyView?.layer.masksToBounds = true
        safetyView?.layer.cornerRadius = viewHeight/2
        safetyView?.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.8)
        self.view.addSubview((safetyView)!)
        self.view.bringSubview(toFront: (safetyView)!)
    }
    
    @IBAction func makeDrawer(){
        if(!drawerOpen){
            let viewHeight = screenHeight/3;
            
            let testFrame: CGRect = CGRect(x: 0, y: screenHeight, width: screenWidth, height: viewHeight)
            currentDrawerView = UIView(frame: testFrame)
            
            bottomContraint.constant = viewHeight-lighthouseButton.frame.height/2
            
            let safetyKeyView = SafetyKeyView.instanceFromNib()
            safetyKeyView.frame.origin = CGPoint(x: 0, y: viewHeight/4)
            currentDrawerView?.addSubview(safetyKeyView)
            
            let settingsButton = UIButton()
            let settingsButtonSize = screenWidth/6
            settingsButton.frame = CGRect(x: screenWidth-(screenWidth/4)-settingsButtonSize/2, y: 3*settingsButtonSize/4, width: settingsButtonSize, height: settingsButtonSize)
            settingsButton.setImage(UIImage(named:"settings"), for: .normal)
            settingsButton.tintColor = UIColor(rgb: SETTINGS_COLOR)
            settingsButton.addTarget(self, action: #selector(settingsButtonAction), for: .touchUpInside)
            currentDrawerView?.addSubview(settingsButton)
            
            
            
            var count:CGFloat = 0
            for buttonNames in CLUSTER_GROUP_NAMES{
                let stateButton = UIButton()
                let iconWidth = screenWidth/6
                let iconSpacing = iconWidth/6
                stateButton.frame = CGRect(x:  count*iconWidth + (count+1)*iconSpacing, y: viewHeight - iconWidth - 10, width: iconWidth, height: iconWidth)
                let currentlySelected:Bool = UserDefaults.standard.bool(forKey: CLUSTER_GROUP_NAMES[Int(count)]+"_state")
                stateButton.isSelected = currentlySelected
                stateButton.tag = Int(count)
                let stateButtonImage = UIImage(named: buttonNames+"_icon")?.withRenderingMode(.alwaysTemplate)
                stateButton.setImage(stateButtonImage, for: .selected)
                stateButton.setImage(stateButtonImage, for: .normal)
                stateButton.layer.borderWidth = 4
                stateButton.layer.cornerRadius = iconWidth/4
                if(currentlySelected){
                    stateButton.tintColor = UIColor(rgb: STATE_BUTTON_SELECT)
                    stateButton.layer.borderColor = UIColor(rgb: STATE_BUTTON_SELECT).cgColor
                }
                else{
                    stateButton.tintColor = UIColor(rgb: STATE_BUTTON_NO_SELECT)
                    stateButton.layer.borderColor = UIColor(rgb: STATE_BUTTON_NO_SELECT).cgColor
                }
                stateButton.addTarget(self, action: #selector(clusterStateButtonAction), for: .touchUpInside)

                currentDrawerView?.addSubview(stateButton)
                count+=1
            }
            
            
            currentDrawerView?.backgroundColor = UIColor(rgb:DRAWER_COLOR).withAlphaComponent(0.8)
            
        
            
            
            
            
            self.view.addSubview((currentDrawerView)!)
            self.view.bringSubview(toFront: (currentDrawerView)!)
            self.view.bringSubview(toFront: lighthouseButton)
            
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                var drawerFrame = self.currentDrawerView?.frame
                let drawerHeight = drawerFrame?.size.height
                drawerFrame?.origin.y -= (drawerHeight)!
                self.currentDrawerView?.frame = drawerFrame!
                
            }, completion: { finished in
                self.drawerOpen = true
            })
            
            
            
        }else{
            bottomContraint.constant = 2
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                var drawerFrame = self.currentDrawerView?.frame
                let drawerHeight = drawerFrame?.size.height
                drawerFrame?.origin.y += (drawerHeight)!
                self.currentDrawerView?.frame = drawerFrame!
                
            }, completion: { finished in
                self.currentDrawerView?.removeFromSuperview()
                self.drawerOpen = false
            })
            
        }
    }
    
   @objc func settingsButtonAction(sender: UIButton!) {
        performSegue(withIdentifier: "toSettingsSegue", sender: nil)
    }
    
    @objc func clusterStateButtonAction(sender: UIButton!) {
        let newState = !sender.isSelected
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            if(newState){
                sender.tintColor = UIColor(rgb: self.STATE_BUTTON_SELECT)
                sender.layer.borderColor = UIColor(rgb: self.STATE_BUTTON_SELECT).cgColor
            }
            else{
                sender.tintColor = UIColor(rgb: self.STATE_BUTTON_NO_SELECT)
                sender.layer.borderColor = UIColor(rgb: self.STATE_BUTTON_NO_SELECT).cgColor
            }
            
        }, completion: { finished in
            
        })
        
        UserDefaults.standard.set(newState, forKey: CLUSTER_GROUP_NAMES[sender.tag]+"_state")
        clusterStates[sender.tag] = newState
        sender.isSelected = newState
        addCrimesToMap(crimeArray: storedCrimes)
    }
    
    
    func addAllStepElements(routeSteps:[RouteStep]){
        polylineArray = []
        let currentRadius = Double(UserDefaults.standard.integer(forKey:"radius"))*0.3048;
        for step in routeSteps{
            
            let currentPath = GMSPath(fromEncodedPath: step.polylinePath)
            let curPoly = GMSPolyline(path: currentPath)
            curPoly.strokeWidth = ROUTE_WIDTH
            curPoly.strokeColor = calculateDangerColorRoute(length: (currentPath?.length(of: .rhumb))!, radius: currentRadius, dangerLevel: calculateDangerForPath(path: currentPath!, radius: currentRadius))
            curPoly.map = mapView
            curPoly.zIndex = 2
            polylineArray.append(curPoly)
            
            let underPoly = GMSPolyline(path: currentPath)
            underPoly.strokeWidth = UNDER_ROUTE_WIDTH
            underPoly.strokeColor = UIColor(rgb: UNDER_ROUTE_COLOR)
            underPoly.map = mapView
            underPoly.zIndex = 1
            polylineArray.append(underPoly)
            
        }

    }
    
    func calculateDangerForPath(path:GMSPath, radius:Double) -> Double{
        var dangerLevel:Double = 0;
        let currentDate = Date()
        var currentPathCrimeCount:Double = 0;
        for crime in storedCrimes{
            if(GMSGeometryIsLocationOnPathTolerance(crime.location, path, false, radius)){
                let userDefinedDanger = UserDefaults.standard.double(forKey: crime.type)
                dangerLevel += crime.calculateSingleThreatScore(userLocation: crime.location, currentDate: currentDate, userValue: userDefinedDanger)
                currentPathCrimeCount += 1.0
                
            }
        }
        return dangerLevel
    }
    
    func calculateDangerColorRoute(length:Double,radius:Double, dangerLevel:Double) -> UIColor{
        let dangerPerSquareMeter = dangerLevel/(radius*length)
        if(dangerPerSquareMeter <= ROUTE_DANGER_RANGES[0]){
            return UIColor(rgb: ROUTE_COLOR[0])
        }
        else if(dangerPerSquareMeter <= ROUTE_DANGER_RANGES[1]){
            return UIColor(rgb: ROUTE_COLOR[1])
        }
        else{
            return UIColor(rgb: ROUTE_COLOR[2])
        }
        
    }
    
    func clearRoute(polySteps:[GMSPolyline]){
        endMarker.map = nil
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
            mapView.animate(toZoom: mapView.camera.zoom + 1)
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
        if(crimeInfoSummary == nil){
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

// MARK: - String

extension String {
    
    var length: Int {
        return self.characters.count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
}
