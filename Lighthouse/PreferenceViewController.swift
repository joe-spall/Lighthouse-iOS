//
//  PreferenceViewController.swift
//  Lighthouse
//
//  Created by Joseph Spall on 7/6/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit

class PreferenceViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //Units Variables
    @IBOutlet weak var unitsSegment: UISegmentedControl!
    
    //Number Format Variables
    @IBOutlet weak var numFormatSegment: UISegmentedControl!
    
    //Date Format Variables
    let dateFormatArray = ["MM/dd/yyyy","dd/MM/yyyy","yyyy/MM/dd"]
    private var dateFormatCellExpanded:Bool = false
    @IBOutlet weak var dateFormatLabel: UILabel!
    @IBOutlet weak var dateFormatPicker: UIPickerView!
    
    //Radius Variables
    let distanceArray = [25,50,100,150,200,250,500]
    private var radiusCellExpanded: Bool = false
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    
    //Year Variables
    let yearArray = ["1900","2012","2013","2014","2015","2016","2017"]
    private var yearCellExpanded: Bool = false
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var yearPicker: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initalizeUnits()
        initalizeNumberFormat()
        initalizeDateFormat()
        initalizeRadius()
        initalizeYear()
        
        
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
        }
        else if(unitsSegment.selectedSegmentIndex == 1){
            UserDefaults.standard.set("meters", forKey:"units")
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
        }
        else if(numFormatSegment.selectedSegmentIndex == 1){
            UserDefaults.standard.set("1.000,00", forKey:"num_format")
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
        yearPicker.selectRow(yearArray.index(of: savedYear!)!, inComponent: 0, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 && indexPath.section == 1 {
            if yearCellExpanded {
                yearCellExpanded = false
            } else {
                yearCellExpanded = true
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
        else if indexPath.row == 0 && indexPath.section == 1{
            if radiusCellExpanded{
                radiusCellExpanded = false
            } else {
                radiusCellExpanded = true
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
        else if indexPath.row == 1 && indexPath.section == 0{
            if dateFormatCellExpanded{
                dateFormatCellExpanded = false
            } else {
                dateFormatCellExpanded = true
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
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 && indexPath.section == 1 {
            if yearCellExpanded {
                return 250
            } else {
                return 50
            }
        }
        
        if indexPath.row == 1 && indexPath.section == 0 {
            if dateFormatCellExpanded {
                return 250
            } else {
                return 50
            }
        }
        
        if indexPath.row == 0 && indexPath.section == 1 {
            if radiusCellExpanded {
                return 150
            } else {
                return 50
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
            returnCount = yearArray.count
        }
        else if(pickerView == dateFormatPicker){
            returnCount = dateFormatArray.count
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
                returnData = yearArray[row]
            }
        }
        else if(pickerView == dateFormatPicker){
            returnData = dateFormatArray[row]
        }
        return returnData
    }
    
    // Capture the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        if(pickerView == yearPicker){
            let yearSelection = yearArray[row]
            if(yearSelection == "1900"){
                yearLabel.text = "All Years"
            }
            else{
                 yearLabel.text = yearSelection
            }
            UserDefaults.standard.set(yearSelection,forKey: "year")
        }
        else if(pickerView == dateFormatPicker){
            let dateFormatSelection = dateFormatArray[row]
            dateFormatLabel.text = dateFormatSelection
            UserDefaults.standard.set(dateFormatSelection,forKey: "date_format")
        }
        
    }
    
    //Radius Slider
    
    func initalizeRadius(){
        let savedRadius = UserDefaults.standard.integer(forKey:"radius")
        radiusSlider.maximumValue = Float(distanceArray.count-1)
        radiusSlider.minimumValue = 0
        radiusSlider.value = Float(distanceArray.index(of: savedRadius)!)
        setRadiusLabel(dist: savedRadius)
    }
    
    @IBAction func valueChanged(sender: UISlider) {
        let newIndexGeneral = radiusSlider.value
        let index = Int(round(newIndexGeneral))
        let newRadius = distanceArray[index]
        radiusSlider.value = Float(index)
        UserDefaults.standard.set(newRadius,forKey:"radius")
        setRadiusLabel(dist: newRadius)
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
        dateFormatPicker.selectRow(dateFormatArray.index(of: savedDateFormat!)!, inComponent: 0, animated: true)
    }
    
    
}
