//
//  ViewController.swift
//  Lighthouse
//
//  Created by Joseph Spall on 6/30/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit
import Alamofire
import Mapbox
import MBProgressHUD
import SwiftyJSON
import SWXMLHash
import MapboxGeocoder

class ViewController: UIViewController, MGLMapViewDelegate {


    @IBOutlet weak var crimeCount: CrimeCountView!
    @IBOutlet var mapView: MGLMapView!
  
    // Constants
    let CRIME_PULL_URL:String = "https://www.app-lighthouse.com/app/crimepullcirc.php"
    let SAFETY_LEVELS:[String] = ["Safe","Low", "Moderate", "High", "Very High", "Dangerous"]
    let SAFETY_VALUES:[Double] = [0.0,3.0,6.0,10.0,20.0,60.0]
    let CLUSTER_RANGES:[Int] = [10, 20, 50, 100, 200]
    let CLUSTER_COLORS:[MGLStyleValue<UIColor>] = [MGLStyleValue(rawValue: UIColor(rgb:0xFEE5D9)),MGLStyleValue(rawValue: UIColor(rgb:0xFCAE91)),MGLStyleValue(rawValue: UIColor(rgb:0xFB6A4A)),MGLStyleValue(rawValue: UIColor(rgb:0xDE2D26)),MGLStyleValue(rawValue: UIColor(rgb:0xA50F15))]
    let CRIME_ICON:UIImage = UIImage(named:"crime_icon")!
    
    var geocoder = Geocoder.shared
    var geocodingDataTask: URLSessionDataTask?
    
    var storedCrimes:[Crime] = []
    var currentCrimeEntryString:String = ""
    var currentDangerLevel:String = ""
    var crimeInfoTotal: UIScrollView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentStyleURL = URL(string: UserDefaults.standard.string(forKey:"map_style")!)
        if(mapView.styleURL.absoluteString != currentStyleURL?.absoluteString)
        {
            mapView.styleURL = currentStyleURL
        }
        
        
        
        //Round edges of crime crime count
        crimeCount.layer.cornerRadius = 10
        mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let currentStyleURL = URL(string: UserDefaults.standard.string(forKey:"map_style")!)
        if(mapView.styleURL.absoluteString != currentStyleURL?.absoluteString)
        {
            mapView.styleURL = currentStyleURL
        }

        // Hide the navigation bar on this view controller
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Show the navigation bar on other view controllers
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    //Mapbox
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        if CLLocationManager.locationServicesEnabled() {
            //TODO handle errors
            //TODO Improve when intial install doesn't recognize location
            switch(CLLocationManager.authorizationStatus()) {
                case .notDetermined, .restricted, .denied:
                    createErrorAlert(description: "Location not accessible")
                case .authorizedAlways, .authorizedWhenInUse:
                    showLoadingHUD()
                    let currentUserLocation = (mapView.userLocation?.coordinate)!
                    mapView.setZoomLevel(17, animated: false)
                    mapView.setCenter(currentUserLocation, animated: true)
                    drawSearchCircle(userLocation:currentUserLocation)
                    pullCrimes(userLocation:currentUserLocation)
                    geocodeSearch(typedElement: "100 10th Street", location: CLLocation(latitude:currentUserLocation.latitude,longitude:currentUserLocation.longitude))
                    hideLoadingHUD()
                
            }
        } else {
            createErrorAlert(description: "Location services are not enabled")
        }
    }
    
    func addCrimesToMap(crimeArray:[Crime]){
        //Gets the current style object of the map.
        guard let style = mapView.style else { return }
        
        //Translates the crime entrys into MGLPointFeatures.
        var collection:[MGLPointFeature] = []
        for crime in crimeArray{
            let tempPointFeature = MGLPointFeature()
            tempPointFeature.coordinate = crime.location
            tempPointFeature.attributes = ["date":formatDate(inputDate:crime.date),"typeCrime":crime.typeCrime]
            collection.append(tempPointFeature)
        }
        
        //Adds the clustering information to the map.
        let shapeCollectionFeature = MGLShapeCollectionFeature(shapes: collection)
        let source = MGLShapeSource(identifier: "clusteredCrimes",shape:shapeCollectionFeature, options: [.clustered: true, .clusterRadius: CRIME_ICON.size.width, .maximumZoomLevelForClustering:20])
        style.addSource(source)
        
        // Use a template image so that we can tint it with the `iconColor` runtime styling property.
        style.setImage(CRIME_ICON.withRenderingMode(.alwaysTemplate), forName: "icon")
        
        // Show unclustered features as icons. The `cluster` attribute is built into clustering-enabled source features.
        let crime = MGLSymbolStyleLayer(identifier: "crime", source: source)
        crime.iconImageName = MGLStyleValue(rawValue: "icon")
        crime.iconColor = MGLStyleValue(rawValue: UIColor.darkGray.withAlphaComponent(0.9))
        crime.predicate = NSPredicate(format: "%K != YES", argumentArray: ["cluster"])
        style.addLayer(crime)
        
        // Color clustered features based on clustered point counts.
        let stops = [
            CLUSTER_RANGES[0]: CLUSTER_COLORS[0],
            CLUSTER_RANGES[1]: CLUSTER_COLORS[1],
            CLUSTER_RANGES[2]: CLUSTER_COLORS[2],
            CLUSTER_RANGES[3]: CLUSTER_COLORS[3],
            CLUSTER_RANGES[4]: CLUSTER_COLORS[4]
        ]
        
        // Show clustered features as circles. The `point_count` attribute is built into clustering-enabled source features.
        let circlesLayer = MGLCircleStyleLayer(identifier: "clusteredCrimes", source: source)
        circlesLayer.circleRadius = MGLStyleValue(rawValue: NSNumber(value: Double(CRIME_ICON.size.width) / 2))
        circlesLayer.circleOpacity = MGLStyleValue(rawValue: 0.75)
        circlesLayer.circleStrokeColor = MGLStyleValue(rawValue: UIColor.white.withAlphaComponent(0.75))
        circlesLayer.circleStrokeWidth = MGLStyleValue(rawValue: 2)
        circlesLayer.circleColor = MGLSourceStyleFunction(interpolationMode: .interval,
                                                          stops: stops,
                                                          attributeName: "point_count",
                                                          options: nil)
        circlesLayer.predicate = NSPredicate(format: "%K == YES", argumentArray: ["cluster"])
        style.addLayer(circlesLayer)
        
        // Label cluster circles with a layer of text indicating feature count.
        let numbersLayer = MGLSymbolStyleLayer(identifier: "clusteredCrimeNumbers", source: source)
        numbersLayer.textColor = MGLStyleValue(rawValue: UIColor.white)
        numbersLayer.textFontSize = MGLStyleValue(rawValue: NSNumber(value: Double(CRIME_ICON.size.width) / 2))
        numbersLayer.iconAllowsOverlap = MGLStyleValue(rawValue: true)
        numbersLayer.text = MGLStyleValue(rawValue: "{point_count}")
        numbersLayer.predicate = NSPredicate(format: "%K == YES", argumentArray: ["cluster"])
        style.addLayer(numbersLayer)
        
        //TODO possibly move to another function to keep the focus on adding the crimes to the map
        let numberFormatter = NumberFormatter()
        let savedNumberFormat = UserDefaults.standard.string(forKey: "num_format")
        if(savedNumberFormat == "1,000.00"){
            numberFormatter.decimalSeparator = "."
            numberFormatter.groupingSeparator = ","
        }
        else{
            numberFormatter.decimalSeparator = ","
            numberFormatter.groupingSeparator = "."
        }
        
        crimeCount.setCrimeNumberLabel(number: numberFormatter.string(from:NSNumber(value: collection.count))!)
        //TODO-END
        
        //Action that handles tapping on a single crime or cluster to reveal information
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        view.addGestureRecognizer(singleTap)
        
    }
    
    //TODO Handle if press on same element
    @objc func handleSingleTap(_ tap: UITapGestureRecognizer) {
        if tap.state == .ended {
            let point = tap.location(in: tap.view)
            let iconWidth = CRIME_ICON.size.width
            let underIconRect = CGRect(x: point.x - iconWidth / 2, y: point.y - iconWidth / 2, width: iconWidth, height: iconWidth)
            let clusters = mapView.visibleFeatures(in: underIconRect, styleLayerIdentifiers: ["clusteredCrimes"])
            let crimes = mapView.visibleFeatures(in: underIconRect, styleLayerIdentifiers: ["crime"])
    
            if clusters.count > 0 {
                showPopup(false, animated: true)
                let cluster = clusters.first!
                if(clusters.count == 1 && mapView.zoomLevel > 18){
                    let clusterLocation = cluster.coordinate
                    let mapCenter = mapView.centerCoordinate
                    if(mapCenter.latitude == clusterLocation.latitude && mapCenter.longitude == clusterLocation.longitude){
                        makePopupForCluster(clusterLocation: clusterLocation)
                    }
                    else{
                        mapView.setCenter(clusterLocation, zoomLevel: mapView.zoomLevel, direction: mapView.direction, animated: true,completionHandler:{() -> Void in
                            self.makePopupForCluster(clusterLocation: clusterLocation)
                        });
                    }
                }
                else{
                    mapView.setCenter(cluster.coordinate, zoomLevel: (mapView.zoomLevel + 1), animated: true)
                }
                
            } else if crimes.count > 0 {
                
                let crime = crimes.first!
                let crimeCord = crime.coordinate
                let mapCenter = mapView.centerCoordinate
                
                if(mapCenter.latitude == crimeCord.latitude && mapCenter.longitude == crimeCord.longitude){
                    makePopupForSingleCrime(crime: crime, crimeCordinate: crimeCord)
                }
                else{
                    mapView.setCenter(crimeCord, zoomLevel: mapView.zoomLevel, direction: mapView.direction, animated: true,completionHandler:{() -> Void in
                        self.makePopupForSingleCrime(crime: crime, crimeCordinate: crimeCord)
                    })
                }
            } else {
                showPopup(false, animated: true)
            }
        }
    }
    
    func makePopupForCluster(clusterLocation:CLLocationCoordinate2D){
        let clusterCenterScreenPoint = mapView.convert(clusterLocation, toPointTo: mapView)
        let clusterSWScreenPoint = CGPoint(x: (clusterCenterScreenPoint.x - CRIME_ICON.size.width), y:(clusterCenterScreenPoint.y + CRIME_ICON.size.width))
        let clusterNEScreenPoint = CGPoint(x: (clusterCenterScreenPoint.x + CRIME_ICON.size.width), y:(clusterCenterScreenPoint.y - CRIME_ICON.size.width))
        let clusterSWMapPoint = mapView.convert(clusterSWScreenPoint, toCoordinateFrom: mapView)
        let clusterNEMapPoint = mapView.convert(clusterNEScreenPoint, toCoordinateFrom: mapView)
        
        let clusterBounds = MGLCoordinateBoundsMake(clusterSWMapPoint, clusterNEMapPoint)
        var infoViewCollection:[CrimeInfoView] = []
        for crimeEntry in storedCrimes{
            let crimeEntryLocation = crimeEntry.location
            if(MGLCoordinateInCoordinateBounds(crimeEntryLocation, clusterBounds)){
                let singleCrimeInfoView:CrimeInfoView = CrimeInfoView()
                let formattedDate:String = formatDate(inputDate: crimeEntry.date)
                let formattedName:String = formatName(inputType: crimeEntry.typeCrime)
                singleCrimeInfoView.setCrimeTypeLabel(type: formattedName)
                singleCrimeInfoView.setCrimeDateLabel(date: formattedDate)
                infoViewCollection.append(singleCrimeInfoView)
            }
        }

        if(infoViewCollection.count > 0){
            crimeInfoTotal = makeCrimeInfoView(viewCollection: infoViewCollection, crimeX: clusterCenterScreenPoint.x, crimeY: clusterCenterScreenPoint.y)
            mapView.addSubview(crimeInfoTotal!)
            //self.showPopup(true, animated: true)
        }
    }
    
    func makePopupForSingleCrime(crime:MGLFeature,crimeCordinate:CLLocationCoordinate2D){
        let singleCrimeInfoView:CrimeInfoView = CrimeInfoView()
        let formattedDate:String = crime.attribute(forKey: "date") as! String
        let formattedName:String = formatName(inputType: crime.attribute(forKey: "typeCrime") as! String)
        singleCrimeInfoView.setCrimeTypeLabel(type: formattedName)
        singleCrimeInfoView.setCrimeDateLabel(date: formattedDate)
        let infoViewCollection:[CrimeInfoView] = [singleCrimeInfoView]
        let crimePoint = mapView.convert(crimeCordinate, toPointTo: mapView)
        
        crimeInfoTotal = makeCrimeInfoView(viewCollection: infoViewCollection, crimeX: crimePoint.x, crimeY: crimePoint.y)
        mapView.addSubview(crimeInfoTotal!)
        //self.showPopup(true, animated: true)
        
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
        return scrollView
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
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        showPopup(false, animated: false)
    }

    func drawSearchCircle(userLocation:CLLocationCoordinate2D) {
        let withMeterRadius = Double(UserDefaults.standard.integer(forKey: "radius"))*0.3048
        let degreesBetweenPoints:Double = 8.0
        let numberOfPoints:Int = 45
        let distRadians: Double = withMeterRadius / 6371000.0
        let centerLatRadians: Double = userLocation.latitude * Double.pi / 180
        let centerLonRadians: Double = userLocation.longitude * Double.pi / 180
        var coordinates = [CLLocationCoordinate2D]()
        
        for index in 0 ..< numberOfPoints {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * Double.pi / 180
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * 180 / Double.pi
            let pointLon: Double = pointLonRadians * 180 / Double.pi
            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
            coordinates.append(point)
        }
        
        let polygon = MGLPolygon(coordinates: &coordinates, count: UInt(coordinates.count))
        polygon.title = "Crime Search Radius"
        mapView.addAnnotation(polygon)
    }
    
    //TODO make occur with change in map
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 0.5
    }
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return .white
    }
    
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return UIColor(red: 59/255, green: 178/255, blue: 208/255, alpha: 1)
    }
    
    //Alamofire
    
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
                            print(error)
                            self.createErrorAlert(description: error.localizedDescription)
                        }
                    }
                    self.addCrimesToMap(crimeArray: self.storedCrimes)
                    self.calculateDanger(crimes: self.storedCrimes,userLoc: userLocation)
                }
                else{
                    print(mightError.string!)
                    self.createErrorAlert(description: mightError.string!)
                }
                
            }
            else {
                print(error!)
                self.createErrorAlert(description: error!)
            }
        }

    }
    
    func formatDate(inputDate:Date) -> String{
        let dateFormatter = DateFormatter()
        let dateFormat = UserDefaults.standard.string(forKey:"date_format")
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from:inputDate)
    }
    
    func formatName(inputType:String) -> String{
        let crimeEntryXML:XMLIndexer = checkCrimeEntryXML()
        var outCrime:String = inputType
        do{
            let readCrime = try crimeEntryXML["danger"]["crime"].withAttribute("type", inputType)["name"].element?.text
            outCrime = (readCrime?.trimmingCharacters(in: .whitespacesAndNewlines))!
        }
        catch{
            print(error)
            
        }
        return outCrime
        
    }
    
    func checkCrimeEntryXML() -> XMLIndexer{
        if(currentCrimeEntryString == ""){
            if let path = Bundle.main.path(forResource: "crime_info", ofType: "xml") {
                let url = URL(fileURLWithPath: path)
                do {
                    currentCrimeEntryString = try String(contentsOf: url, encoding: String.Encoding.utf8)
                }
                catch {
                    print(error)
                    //TODO Error Handle if file is unavailable
                }
            }
        }
        return SWXMLHash.parse(currentCrimeEntryString)
    }
    
    func calculateDanger(crimes:[Crime],userLoc:CLLocationCoordinate2D){
        
        let currentCrimeEntryXML:XMLIndexer = checkCrimeEntryXML()
        var dangerNumber:Double = 0
        let currentDate:Date = Date()
        for crime in crimes{
            let singleCrimeType = crime.typeCrime
            do{
                //let singleTargetScore = try currentCrimeEntryXML["danger"]["crime"].withAttribute("type", singleCrimeType)["target_score"].element?.text.trimmingCharacters(in: .whitespacesAndNewlines)
                //let singleFBIScore = try currentCrimeEntryXML["danger"]["crime"].withAttribute("type", singleCrimeType)["fbi_score"].element?.text.trimmingCharacters(in: .whitespacesAndNewlines)
                let currentCrimeScore = crime.calculateSingleThreatScore(userLocation: userLoc, currentDate: currentDate)
                
                dangerNumber += currentCrimeScore
            }
            catch{
                print(error)
                //TODO Error Handle
                
            }
        }
        
        if(dangerNumber > 0){
            let currentRadius = Double(UserDefaults.standard.integer(forKey:"radius"))
            let currentArea = Double.pi*pow(currentRadius,2)
            let currentNumberOfCrimes = Double(crimes.count)
            do{
                dangerNumber /= currentNumberOfCrimes
            }
            catch{
                print(error)
            }
            
            //TODO Implement crime density
        }
        
        for i in 0...SAFETY_VALUES.count-2{
            if(dangerNumber >= SAFETY_VALUES[i] && dangerNumber < SAFETY_VALUES[i+1]){
                currentDangerLevel = SAFETY_LEVELS[i]
                break
            }
        }
        
        if(currentDangerLevel != ""){
            crimeCount.setCrimeLevelLabel(level: currentDangerLevel)
        }
        else{
            crimeCount.setCrimeLevelLabel(level: SAFETY_LEVELS[SAFETY_LEVELS.count-1])
        }
        
    }
    
    
    //MBProgressHUD
    
    private func showLoadingHUD() {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Loading..."
    }
    
    private func hideLoadingHUD() {
        MBProgressHUD.hide(for: self.view, animated: true)
    }
    
    //Error Handling
    
    func createErrorAlert(description:String){
        let alert = UIAlertController(title: "Alert", message: description, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //TODO Geocoding stufff
    
    func geocodeSearch(typedElement:String, location:CLLocation){
        let options = ForwardGeocodeOptions(query: typedElement)
        options.allowedISOCountryCodes = ["US"]
        options.focalLocation = location
        options.allowedScopes = [.address,.pointOfInterest]
        let task = geocoder.geocode(options) { (placemarks, attribution, error) in
            guard let placemark = placemarks?.first else {
                return
            }
            
            print(placemark.name)
            
            print(placemark.qualifiedName)
            
            let coordinate = placemark.location.coordinate
            print("\(coordinate.latitude), \(coordinate.longitude)")
        }
        
        
    }
    

}

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

