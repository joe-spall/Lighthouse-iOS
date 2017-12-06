//
//  AppDelegate.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 10/7/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps
import GooglePlaces
import SwiftyJSON
import AlamofireNetworkActivityIndicator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let GOOGLE_MAP_API:String = "AIzaSyAoQH-GwOO8okM0krrHyP1hLv6VVl5U2to"
    
    let SETTING_KEYS:[String] = ["load_before","units","year","date_format","num_format","map_style","danger_loaded","rape_state","assault_state","homicide_state","car_theft_state","ped_theft_state"]
    let DEFAULT_VALUES_STRINGS:[Any] = [true,"feet","2015","MM/dd/yyyy","1,000.00","Normal",true,true,true,true,true,true]
    let SETTING_KEYS_INT:[String] = ["radius"]
    let DEFAULT_VALUES_INT:[Int] = [100]

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        initDangerLevel()
        initUserDefaults()
        GMSPlacesClient.provideAPIKey(GOOGLE_MAP_API)
        GMSServices.provideAPIKey(GOOGLE_MAP_API)
        NetworkActivityIndicatorManager.shared.isEnabled = true

        
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "lighthouse_gmaps")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func initUserDefaults(){
        var count:Int = 0
        for key in SETTING_KEYS{
            if !isKeyPresentInUserDefaults(key: key){
                UserDefaults.standard.set(DEFAULT_VALUES_STRINGS[count],forKey:key)
            }
            count += 1
        }
        count = 0
        for key in SETTING_KEYS_INT{
            if !isKeyPresentInUserDefaults(key: key){
                UserDefaults.standard.set(Int(DEFAULT_VALUES_INT[count]),forKey:key)
            }
            count += 1
        }
        
    }
    
    func initDangerLevel(){
        if(!isKeyPresentInUserDefaults(key: "danger_loaded")){
            let url = Bundle.main.url(forResource: "danger_file", withExtension: "json")
            do{
                let data = try Data(contentsOf: url!)
                let totalJSON = JSON(data:data)
                let valueArray = totalJSON["danger"].array
                for entry in valueArray!{
                    let tagName = entry["tag"].string;
                    if(!isKeyPresentInUserDefaults(key: tagName!)){
                        UserDefaults.standard.set(Float(1), forKey: tagName!)
                    }
                    
                }
            }
            catch{
                print(error)
            }
        }
        
    }

}

