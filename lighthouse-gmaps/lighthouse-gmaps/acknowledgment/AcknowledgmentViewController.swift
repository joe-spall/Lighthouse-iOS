//
//  AttributionViewController.swift
//  Lighthouse
//
//  Created by Joseph Spall on 7/6/17.
//  Copyright © 2017 Lighthouse. All rights reserved.
//

import UIKit

class AttributionViewController: UITableViewController,XMLParserDelegate {
    
    var attributions:[Attribution] = []
    var eName: String = String()
    var atrLibrary = String()
    var atrLicense = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let path = Bundle.main.url(forResource: "ack_storage", withExtension: "xml") {
            if let parser = XMLParser(contentsOf: path) {
                parser.delegate = self
                parser.parse()
            }
            //TODO Error if acknowledgments not found
        }
        tableView.estimatedRowHeight = 43.0;
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return attributions.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return attributions[section].library
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AckCell", for: indexPath)
        
        let attribution = attributions[indexPath.section]
        cell.textLabel?.text = attribution.license
        cell.textLabel?.sizeToFit()
        cell.textLabel?.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
    
    //Parser
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        eName = elementName
        if elementName == "entry" {
            atrLibrary = String()
            atrLicense = String()
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "entry" {
            
            let entry = Attribution(library: atrLibrary,license: atrLicense)
            attributions.append(entry)
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let data = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        if (!data.isEmpty) {
            if eName == "library" {
                atrLibrary += data
            } else if eName == "license" {
                atrLicense += data
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
    
}

struct Attribution {
    let library:String
    let license:String
}
