//
//  InitialLoadViewController.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 11/9/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit
import SwiftyJSON

class InitialLoadViewController: UIViewController {

    
    @IBOutlet weak var termsTextView: UITextView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var termsSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(isKeyPresentInUserDefaults(key: "terms_conditions"))
        {
            sendToMapView()
        }
        initTermsAndConditions()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @IBAction func continueAction(sender: AnyObject){
        if(!termsSwitch.isOn){
            let description = "Please accept the Terms and Conditions."
            let alert = UIAlertController(title: "Alert", message: description, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        else{
            UserDefaults.standard.set(true, forKey: "terms_conditions")
            sendToMapView()
        }
        
        
    }
    
    func sendToMapView(){
        let transition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromBottom
        navigationController?.view.layer.add(transition, forKey: nil)
        self.navigationController?.popViewController(animated: false)
    }

    func initTermsAndConditions(){
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
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
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
