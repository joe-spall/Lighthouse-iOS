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
    
    //Date Format Variables
    let formatArray = ["MM/DD/YYYY","DD/MM/YYYY","YYYY/MM/DD"]
    private var formatCellExpanded:Bool = false
    @IBOutlet weak var formatLabel: UILabel!
    @IBOutlet weak var formatPicker: UIPickerView!
    
    //Radius Variables
    let distanceArray = [50,100,150,200,250,500,1000,1320,2640,3960,5280]
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
        initalizeFormat()
        initalizeRadius()
        initalizeYear()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Units segment
    func initalizeUnits(){
        let savedUnits = UserDefaults.standard.string(forKey: "units")
        if(savedUnits == "feet"){
            unitsSegment.selectedSegmentIndex = 0
        }
        else{
            unitsSegment.selectedSegmentIndex = 1
        }
    }
    
    @IBAction func segmentedControlAction(sender: AnyObject) {
        if(unitsSegment.selectedSegmentIndex == 0){
            UserDefaults.standard.set("feet", forKey:"units")
            
        }
        else if(unitsSegment.selectedSegmentIndex == 1){
            UserDefaults.standard.set("meters", forKey:"units")
        }
        initalizeRadius()
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
            
            if formatCellExpanded{
                formatCellExpanded = false
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
            
            if formatCellExpanded{
                formatCellExpanded = false
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        else if indexPath.row == 1 && indexPath.section == 0{
            if formatCellExpanded{
                formatCellExpanded = false
            } else {
                formatCellExpanded = true
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
            if formatCellExpanded {
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
        else if(pickerView == formatPicker){
            returnCount = formatArray.count
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
        else if(pickerView == formatPicker){
            returnData = formatArray[row]
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
        else if(pickerView == formatPicker){
            let formatSelection = formatArray[row]
            formatLabel.text = formatSelection
            UserDefaults.standard.set(formatSelection,forKey: "format")
        }
        
    }
    
    //Radius Slider
    
    func initalizeRadius(){
        let savedRadius = UserDefaults.standard.integer(forKey:"radius")
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
            if(dist > 1000){
                radiusLabel.text = String(format: "%.02f",Float(dist)/5280) + " miles"
            }
            else{
                radiusLabel.text = String(dist) + " feet"
            }
        }
        else{
            let metersFromFeet = round(Double(dist)*0.3048)
            if(metersFromFeet > 1000){
                radiusLabel.text = String(format: "%.02f",Float(metersFromFeet)/1000) + " kilometers"
            }
            else{
                radiusLabel.text = String(metersFromFeet) + " meters"
            }
        }
    }
    
    //Format Picker
    
    func initalizeFormat(){
        self.formatPicker.delegate = self
        self.formatPicker.dataSource = self
        tableView.tableFooterView = UIView()
        let savedFormat = UserDefaults.standard.string(forKey: "format")
        formatLabel.text = savedFormat
        formatPicker.selectRow(formatArray.index(of: savedFormat!)!, inComponent: 0, animated: true)
    }
    
    
    
}
