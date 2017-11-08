//
//  CrimeWeightSettingsViewController.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 10/7/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit
import SwiftyJSON

class CrimeWeightViewController: UITableViewController{

    var totalJSON:JSON = JSON.null
    var crimeSlide:[CrimeWeight] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
        initCrimeSlide()
        
        tableView.rowHeight = 75.0;
        //tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewController
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return crimeSlide.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CrimeWeightTableViewCell
        if(totalJSON != JSON.null)
        {
            let singleCrimeSlide = crimeSlide[indexPath.row]
            cell.crimeTag = singleCrimeSlide.tag
            cell.crimeNameLabel.text = singleCrimeSlide.name
            cell.crimeNameLabel.sizeToFit()
            cell.crimeNameLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            cell.crimeNameLabel.numberOfLines = 0
            cell.setDangerLabel(score: singleCrimeSlide.dangerValue)
            cell.dangerSlider.value = singleCrimeSlide.dangerValue
        }
        return cell
    }
    
    // MARK: - DangerValue
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func initCrimeSlide(){
        let url = Bundle.main.url(forResource: "danger_file", withExtension: "json")
        do{
            let data = try Data(contentsOf: url!)
            totalJSON = JSON(data:data)
            let valueArray = totalJSON["danger"].array
            for entry in valueArray!{
                let tagName = entry["tag"].string;
                let userName = entry["name"].string;

                if(isKeyPresentInUserDefaults(key: tagName!)){
                    let tempSetWeight:Float = UserDefaults.standard.float(forKey: tagName!)
                    let tempCrimeWeight:CrimeWeight = CrimeWeight(tag: tagName!, name: userName!, dangerValue: tempSetWeight)
                    crimeSlide.append(tempCrimeWeight)
                }
                else{
                    UserDefaults.standard.set(Float(1), forKey: tagName!)
                    let tempCrimeWeight:CrimeWeight = CrimeWeight(tag: tagName!, name: userName!, dangerValue: Float(1))
                    crimeSlide.append(tempCrimeWeight)
                }
            }
        }
        catch{
            print(error)
        }
    }
    
}

struct CrimeWeight{
    let tag:String
    let name:String
    var dangerValue:Float
}

