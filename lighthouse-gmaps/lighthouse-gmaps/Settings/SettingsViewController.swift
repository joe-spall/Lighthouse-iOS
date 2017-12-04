//
//  SettingsViewController.swift
//  Lighthouse
//
//  Created by Joseph Spall on 7/6/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource{
    
    //TODO Add arrows for transitioning elements
    
    //Units Variables
    @IBOutlet weak var unitsSegment: UISegmentedControl!
    
    //Number Format Variables
    @IBOutlet weak var numFormatSegment: UISegmentedControl!
    
    //Date Format Variables
    let DATE_FORMAT_OPTIONS:[String] = ["MM/dd/yyyy","dd/MM/yyyy","yyyy/MM/dd"]
    private var dateFormatCellExpanded:Bool = false
    @IBOutlet weak var dateFormatLabel: UILabel!
    @IBOutlet weak var dateFormatPicker: UIPickerView!
    
    //Radius Variables
    let DISTANCE_OPTIONS:[Int] = [25,50,100,150,200,250,500]
    private var radiusCellExpanded: Bool = false
    var lastRadius:Int = 0
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    
    //Year Variables
    let YEAR_OPTIONS:[String] = ["1900","2012","2013","2014","2015","2016","2017"]
    private var yearCellExpanded: Bool = false
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var yearPicker: UIPickerView!
    
    
    //Map Styles Variables
    let MAP_STYLE_NAME_OPTIONS:[String] = ["Normal","Hybrid","Satellite","Terrain"]
    private var mapStyleCellExpanded:Bool = false
    @IBOutlet weak var mapStyleLabel: UILabel!
    @IBOutlet weak var mapStylePicker: UIPickerView!
    
    // MARK: Settings Changed
    var settingsChanged:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        initalizeUnits()
        initalizeNumberFormat()
        initalizeDateFormat()
        initalizeRadius()
        initalizeYear()
        initalizeMapStyle()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Units segment
    func initalizeUnits(){
        let savedUnits:String = UserDefaults.standard.string(forKey: "units")!
        if(savedUnits == "feet"){
            unitsSegment.selectedSegmentIndex = 0
        }
        else{
            unitsSegment.selectedSegmentIndex = 1
        }
    }
    
    @IBAction func unitSegmentedControlAction(sender: AnyObject) {
        if(unitsSegment.selectedSegmentIndex == 0){
            UserDefaults.standard.set("feet", forKey:"units")
            settingsChanged = true
        }
        else if(unitsSegment.selectedSegmentIndex == 1){
            UserDefaults.standard.set("meters", forKey:"units")
            settingsChanged = true
        }
        initalizeRadius()
    }
    
    //Number Format Segment
    
    func initalizeNumberFormat(){
        let savedNumberFormat:String = UserDefaults.standard.string(forKey: "num_format")!
        if(savedNumberFormat == "1,000.00"){
            numFormatSegment.selectedSegmentIndex = 0
        }
        else{
            numFormatSegment.selectedSegmentIndex = 1
        }
    }
    
    @IBAction func numberSegmentedControlAction(sender: AnyObject) {
        if(numFormatSegment.selectedSegmentIndex == 0){
            UserDefaults.standard.set("1,000.00", forKey:"num_format")
            settingsChanged = true
        }
        else if(numFormatSegment.selectedSegmentIndex == 1){
            UserDefaults.standard.set("1.000,00", forKey:"num_format")
            settingsChanged = true
        }
    }
    
    
    //Year picker
    func initalizeYear(){
        self.yearPicker.delegate = self
        self.yearPicker.dataSource = self
        tableView.tableFooterView = UIView()
        let savedYear = UserDefaults.standard.string(forKey: "year")
        if(savedYear == "1900"){
            yearLabel.text = "All Years"
        }
        else{
            yearLabel.text = savedYear
        }
        yearPicker.selectRow(YEAR_OPTIONS.index(of: savedYear!)!, inComponent: 0, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //TODO Translate to not hard-coded
        if indexPath.row == 2 && indexPath.section == 1 {
            if yearCellExpanded {
                yearCellExpanded = false
            } else {
                yearCellExpanded = true
            }
            
            if mapStyleCellExpanded{
                mapStyleCellExpanded = false
            }
            
            if radiusCellExpanded{
                radiusCellExpanded = false
            }
            
            if dateFormatCellExpanded{
                dateFormatCellExpanded = false
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        else if indexPath.row == 1 && indexPath.section == 1{
            if radiusCellExpanded{
                radiusCellExpanded = false
            } else {
                radiusCellExpanded = true
            }
            
            if mapStyleCellExpanded{
                mapStyleCellExpanded = false
            }
            
            if yearCellExpanded{
                yearCellExpanded = false
            }
            
            if dateFormatCellExpanded{
                dateFormatCellExpanded = false
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        else if indexPath.row == 3 && indexPath.section == 0{
            if dateFormatCellExpanded{
                dateFormatCellExpanded = false
            } else {
                dateFormatCellExpanded = true
            }
            
            if mapStyleCellExpanded{
                mapStyleCellExpanded = false
            }
            
            if yearCellExpanded{
                yearCellExpanded = false
            }
            
            if radiusCellExpanded{
                radiusCellExpanded = false
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        else if indexPath.row == 2 && indexPath.section == 0{
            if mapStyleCellExpanded{
                mapStyleCellExpanded = false
            } else {
                mapStyleCellExpanded = true
            }
            
            if yearCellExpanded{
                yearCellExpanded = false
            }
            
            if radiusCellExpanded{
                radiusCellExpanded = false
            }
            
            if dateFormatCellExpanded{
                dateFormatCellExpanded = false
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
            
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //TODO Translate to not hard-coded
        if indexPath.row == 2 && indexPath.section == 1 {
            if yearCellExpanded {
                return 250
            }
        }
        
        if indexPath.row == 3 && indexPath.section == 0 {
            if dateFormatCellExpanded {
                return 250
            }
        }
        
        if indexPath.row == 1 && indexPath.section == 1 {
            if radiusCellExpanded {
                return 150
            }
        }
        
        if indexPath.row == 2 && indexPath.section == 0{
            if mapStyleCellExpanded {
                return 250
            }
        }
        
        return 50
    }
    
    @available(iOS 2.0, *)
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var returnCount:Int = 0
        if(pickerView == yearPicker){
            returnCount = YEAR_OPTIONS.count
        }
        else if(pickerView == dateFormatPicker){
            returnCount = DATE_FORMAT_OPTIONS.count
        }
        else if(pickerView == mapStylePicker){
            returnCount = MAP_STYLE_NAME_OPTIONS.count
        }
        return returnCount
        
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var returnData:String = ""
        if(pickerView == yearPicker){
            if(row == 0){
                returnData = "All Years"
            }
            else{
                returnData = YEAR_OPTIONS[row]
            }
        }
        else if(pickerView == dateFormatPicker){
            returnData = DATE_FORMAT_OPTIONS[row]
        }
        else if(pickerView == mapStylePicker){
            returnData = MAP_STYLE_NAME_OPTIONS[row]
        }
        return returnData
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        if(pickerView == yearPicker){
            let yearSelection = YEAR_OPTIONS[row]
            if(yearSelection == "1900"){
                yearLabel.text = "All Years"
            }
            else{
                yearLabel.text = yearSelection
            }
            UserDefaults.standard.set(yearSelection,forKey: "year")
            settingsChanged = true
        }
        else if(pickerView == dateFormatPicker){
            let dateFormatSelection = DATE_FORMAT_OPTIONS[row]
            dateFormatLabel.text = dateFormatSelection
            UserDefaults.standard.set(dateFormatSelection,forKey: "date_format")
            settingsChanged = true
        }
        else if(pickerView == mapStylePicker){
            let mapStyleNameSelection = MAP_STYLE_NAME_OPTIONS[row]
            mapStyleLabel.text = mapStyleNameSelection
            UserDefaults.standard.set(mapStyleNameSelection, forKey:"map_style")
            settingsChanged = true
        }
        
    }
    
    //Radius Slider
    //TODO Add numbers for ranges on slider UI
    func initalizeRadius(){
        let savedRadius = UserDefaults.standard.integer(forKey:"radius")
        lastRadius = savedRadius
        radiusSlider.maximumValue = Float(DISTANCE_OPTIONS.count-1)
        radiusSlider.minimumValue = 0
        radiusSlider.value = Float(DISTANCE_OPTIONS.index(of: savedRadius)!)
        setRadiusLabel(dist: savedRadius)
    }
    
    @IBAction func radiusSliderValueChanged(sender: UISlider) {
        let newIndexGeneral = radiusSlider.value
        let index = Int(round(newIndexGeneral))
        let newRadius = DISTANCE_OPTIONS[index]
        radiusSlider.value = Float(index)
        if(newRadius != lastRadius){
            setRadiusLabel(dist: newRadius)
            lastRadius = newRadius
        }
    }
    
    @IBAction func radiusSliderEndChange(sender: UISlider) {
        let newIndexGeneral = radiusSlider.value
        let index = Int(round(newIndexGeneral))
        let newRadius = DISTANCE_OPTIONS[index]
        radiusSlider.value = Float(index)
        UserDefaults.standard.set(newRadius,forKey:"radius")
        settingsChanged = true
    }
    
    func setRadiusLabel(dist: Int){
        if (UserDefaults.standard.string(forKey:"units") == "feet"){
            radiusLabel.text = String(dist) + " ft"
        }
        else{
            let metersFromFeet:Int = Int(Double(dist)*0.3048)
            radiusLabel.text = String(metersFromFeet) + " m"
        }
    }
    
    //Date Format Picker
    
    func initalizeDateFormat(){
        self.dateFormatPicker.delegate = self
        self.dateFormatPicker.dataSource = self
        tableView.tableFooterView = UIView()
        let savedDateFormat = UserDefaults.standard.string(forKey: "date_format")
        dateFormatLabel.text = savedDateFormat
        dateFormatPicker.selectRow(DATE_FORMAT_OPTIONS.index(of: savedDateFormat!)!, inComponent: 0, animated: true)
    }
    
    //Map Style Picker
    
    func initalizeMapStyle(){
        self.mapStylePicker.delegate = self
        self.mapStylePicker.dataSource = self
        tableView.tableFooterView = UIView()
        let mapStyleName = UserDefaults.standard.string(forKey: "map_style")
        let mapStyleIndex:Int = MAP_STYLE_NAME_OPTIONS.index(of: mapStyleName!)!
        mapStyleLabel.text = mapStyleName
        mapStylePicker.selectRow(mapStyleIndex, inComponent: 0, animated: true)
        
    }
    
}

extension SettingsViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let controller = viewController as? MapViewController {
            controller.settingsChanged = self.settingsChanged
            print(controller.settingsChanged)
        }
    }
}
