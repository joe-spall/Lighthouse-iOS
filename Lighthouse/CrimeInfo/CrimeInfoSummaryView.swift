//
//  TotalCrimeInfoView.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 10/25/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit

class CrimeInfoSummaryView: UIView {

    var stackView:UIStackView = UIStackView()
    var scrollView:UIScrollView = UIScrollView()
    
    //TODO make initalizer
    
    func makeViewForCluster(crimeCluster:GMUCluster){
        var infoViewCollection:[CrimeInfoEntryView] = []
        let clusterItems = crimeCluster.items
        for singleCrimeItem in clusterItems{
            infoViewCollection.append(makeSingleCrimeInfoView(crime: (singleCrimeItem as! CrimeClusterItem).crime))
        }
        makeCrimeInfoView(viewCollection: infoViewCollection)
        
    }
    
     func makeViewForSingle(crimeItem:CrimeClusterItem){
        let currentCrime:Crime = crimeItem.crime
        let infoViewCollection:[CrimeInfoEntryView] = [makeSingleCrimeInfoView(crime: currentCrime)]
        makeCrimeInfoView(viewCollection: infoViewCollection)
    }
    
    func makeSingleCrimeInfoView(crime:Crime) -> CrimeInfoEntryView{
        let singleCrimeInfoView = CrimeInfoEntryView.loadViewFromNib() as! CrimeInfoEntryView
        singleCrimeInfoView.setAllCrimeInfo(currentCrime: crime)
        return singleCrimeInfoView
    }
    
    func makeCrimeInfoView(viewCollection: [CrimeInfoEntryView]){
        //TODO Make the weight calculation dynamic
        let maxWidth:CGFloat = 227.0
        let maxHeight:CGFloat = 66.0
        //TODO-END
        
        stackView = UIStackView(arrangedSubviews: viewCollection.reversed())
        stackView.axis = UILayoutConstraintAxis.vertical
        stackView.distribution  = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.center
        stackView.spacing = 3.0
        stackView.frame = CGRect(x: 0, y: 0, width: maxWidth, height: maxHeight*CGFloat(viewCollection.count))

        if(viewCollection.count > 3){
            scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: maxWidth, height: maxHeight*CGFloat(3)-(maxHeight/3)))
        }
        else{
            scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: maxWidth, height: CGFloat(viewCollection.count)*maxHeight))
        }
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor(red:0/255.0, green:0/255.0, blue:0/255.0, alpha: 1.0).cgColor
        scrollView.layer.cornerRadius = 10
        scrollView.contentSize = stackView.bounds.size
        scrollView.backgroundColor = UIColor(red:1, green:1, blue:1, alpha: 0.5)
        scrollView.addSubview(stackView)
        self.frame = scrollView.frame
        self.alpha = 0
        self.addSubview(scrollView)
        
        
    }
    
    func numberOfCrimes() -> Int{
        return stackView.arrangedSubviews.count
        
    }
    
    
    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
