//
//  MapClusterIconGenerator.swift
//  lighthouse-gmaps
//
//  Created by Joseph Spall on 10/24/17.
//  Copyright © 2017 LightHouse. All rights reserved.
//

import UIKit

class MapClusterIconGenerator: GMUDefaultClusterIconGenerator {
    
    override func icon(forSize size: UInt) -> UIImage {
        let image = textToImage(drawText: String(size) as NSString,
                                inImage: UIImage(named: "cluster")!,
                                font: UIFont.systemFont(ofSize: 12))
        return image
    }
    
    private func textToImage(drawText text: NSString, inImage image: UIImage, font: UIFont) -> UIImage {
        
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = NSTextAlignment.center
        let textColor = UIColor.black
        let attributes=[
            NSAttributedStringKey.font: font,
            NSAttributedStringKey.paragraphStyle: textStyle,
            NSAttributedStringKey.foregroundColor: textColor]
        
        // vertically center (depending on font)
        let textH = font.lineHeight
        let textY = (image.size.height-textH)/2
        let textRect = CGRect(x: 0, y: textY, width: image.size.width, height: textH)
        text.draw(in: textRect.integral, withAttributes: attributes)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
}
