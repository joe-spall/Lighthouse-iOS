//
//  TermsOfServiceViewController.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 12/4/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit
import SwiftyJSON

class TermsOfServiceViewController: UIViewController {

    @IBOutlet weak var termsTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        initTermsOfService()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func initTermsOfService(){
        let url = Bundle.main.url(forResource: "legal", withExtension: "json")
        do{
            let data = try Data(contentsOf: url!)
            let totalJSON = JSON(data: data)
            let termsAndConditions = totalJSON["legal"][0]["terms_and_conditions"].string
            termsTextView.text = termsAndConditions
            termsTextView.scrollRangeToVisible(NSMakeRange(0, 0))
        }
        catch{
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
