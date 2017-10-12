//
//  CrimeSlidersViewController.swift
//  Lighthouse
//
//  Created by Joseph Spall on 9/11/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit

class CrimeSlidersViewController: UITableViewController,XMLParserDelegate {

    var crimeSlide:[CrimeSlide] = []
    var crimePreference:[String:Float] = [:]
    var eName: String = String()
    var crmName = String()
    var dngValue = Float(1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        // Do any additional setup after loading the view.
        if let path = Bundle.main.url(forResource: "crime_info", withExtension: "xml") {
            if let parser = XMLParser(contentsOf: path) {
                parser.delegate = self
                parser.parse()
            }
        }
        tableView.rowHeight = 75.0;
        //tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return crimeSlide.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CrimeSlideTableViewCell
        
        let singleCrimeSlide = crimeSlide[indexPath.row]
        cell.crimeNameLabel.text = singleCrimeSlide.crimeName
        cell.crimeNameLabel.sizeToFit()
        cell.crimeNameLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.crimeNameLabel.numberOfLines = 0
        
        cell.setDangerLabel(score: singleCrimeSlide.dangerValue)
        
        cell.dangerSlider.value = singleCrimeSlide.dangerValue
        
        
        return cell
    }
    
    //Parser
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        eName = elementName
        if elementName == "crime" {
            crmName = String()
            dngValue = Float(1)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "crime" {
            //TODO Implement an initial install
            if(isKeyPresentInUserDefaults(key: crmName)){
                dngValue = UserDefaults.standard.float(forKey:crmName)
            }
            else{
                UserDefaults.standard.set(dngValue,forKey: crmName)
            }
            let entry = CrimeSlide(crimeName: crmName, dangerValue: dngValue)
            crimeSlide.append(entry)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (!data.isEmpty) {
            if eName == "name" {
                crmName += data
            }
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

    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
}
