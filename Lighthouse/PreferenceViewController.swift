//
//  PreferenceViewController.swift
//  
//
//  Created by Joseph Spall on 7/1/17.
//
//

import UIKit

class PreferenceViewController: UITableViewController {
    
    let distanceArray = [50,100,150,200,250,500,1000,1320,2640,3960,5280]
    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        intializeRadius()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if(dist > 1000){
            radiusLabel.text = String(format: "%.02f",Float(dist)/5280) + " miles"
        }
        else{
            radiusLabel.text = String(dist) + " feet"
        }
    }
    
    func intializeRadius(){
        let savedRadius = UserDefaults.standard.integer(forKey:"radius")
        radiusSlider.value = Float(distanceArray.index(of: savedRadius)!)
        setRadiusLabel(dist: savedRadius)
    }
    
    
}
