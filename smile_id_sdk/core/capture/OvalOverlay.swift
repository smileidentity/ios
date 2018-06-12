//
//  OvalOverlay.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/8/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class OvalOverlay {
    
    /* Draws an oval, and returns a rectangle containing the oval */
    func createOvalMask( previewRect : CGRect,
                videoPreviewLayer: AVCaptureVideoPreviewLayer) -> CGRect {
        /* Create the oval mask
         Oval mask is positioned 10% within the preview frame.
         */
        let border = previewRect.width * 0.2/2.0
        let x = border
        let width = previewRect.width - (border*2)
        let y = border
        let height = previewRect.height -  (border*2)
    
        let ovalRect =  CGRect( x:x, y:y, width:width, height:height)
        let bezierPath = UIBezierPath(ovalIn:ovalRect)
    
    
        let ovalMaskLayer = CAShapeLayer()
        ovalMaskLayer.path = bezierPath.cgPath
        videoPreviewLayer.mask = ovalMaskLayer
    
        /* Create blue oval.  iOS does not support drawing arcs for ellipsys */
    
        let ovalColor = UIColor( red: 0.0/255.0,
            green: 180.0/255.0,
            blue: 255.0/255.0,
            alpha : 0.7 )
    
    
        let blueOvalLayer = CAShapeLayer()
        blueOvalLayer.path = bezierPath.cgPath
        blueOvalLayer.fillColor = UIColor.clear.cgColor
        blueOvalLayer.strokeColor = ovalColor.cgColor
        let lineWidth = previewRect.width * 0.1
        blueOvalLayer.lineWidth = lineWidth
        videoPreviewLayer.addSublayer(blueOvalLayer)
    
        return ovalRect

    }
    
}

