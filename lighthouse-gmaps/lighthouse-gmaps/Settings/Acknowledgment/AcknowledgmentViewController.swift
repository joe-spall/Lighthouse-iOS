//
//  AcknowledgmentViewController.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 12/1/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit
import SwiftyJSON

class AcknowledgmentViewController: UITableViewController {
    
    var totalJSON:JSON = JSON.null
    var acknowledgeArray:[Acknowledge] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        initAcknowledgment()
        
        tableView.estimatedRowHeight = 43.0
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return acknowledgeArray.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return acknowledgeArray[section].library
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AckCell", for: indexPath)
        if(totalJSON != JSON.null)
        {
            let individualAcknowledge = acknowledgeArray[indexPath.section]
            cell.textLabel?.text = individualAcknowledge.license
            cell.textLabel?.lineBreakMode = .byWordWrapping
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.sizeToFit()
            
            
        }
        else{
            //TODO: Fix with more meaningful error
            print("Something went wrong")
        }
        return cell
    }
    
    func initAcknowledgment(){
        let url = Bundle.main.url(forResource: "acknowledge", withExtension: "json")
        do{
            let data = try Data(contentsOf: url!)
            totalJSON = JSON(data:data)
            let valueArray = totalJSON["acknowledge"].array
            for entry in valueArray!{
                let libraryName = entry["library"].string;
                let licenseText = entry["license"].string;
                acknowledgeArray.append(Acknowledge(library:libraryName!,license:licenseText!))
            }
        }
        catch{
            //TODO: Fix with more meaningful error
            print(error)
        }
        
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

struct Acknowledge{
    let library:String
    let license:String
}
