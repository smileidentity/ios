//
//  IDCardOverlay.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/17/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class IDCardOverlay {
    
    let maskThicknessLeftRight      : CGFloat = 80.0
    let maskThicknessTopBottom      : CGFloat = 50.0
    var maskWidth                   : CGFloat?
    var maskHeight                  : CGFloat?
    
    func getLeftRightMaskWidth() -> CGFloat {
        return maskThicknessLeftRight
    }
    func getTopBottomMaskWidth() -> CGFloat {
        return maskThicknessTopBottom
    }
    func getMaskWidth() -> CGFloat {
        return maskWidth!
    }
    func getMaskHeight() -> CGFloat{
        return maskHeight!
    }

    

    
    
    func createRectMask( videoPreviewLayer: AVCaptureVideoPreviewLayer ) {
        
        maskWidth = videoPreviewLayer.frame.width - (maskThicknessLeftRight*2)
        maskHeight = videoPreviewLayer.frame.height - (maskThicknessTopBottom*2)
        
        addBorder(  videoPreviewLayer: videoPreviewLayer,
                    edge: UIRectEdge.top,
                    thickness: CGFloat(maskThicknessTopBottom))
        addBorder(  videoPreviewLayer: videoPreviewLayer,
                    edge: UIRectEdge.bottom,
                    thickness: CGFloat(maskThicknessTopBottom) )
        addBorder(  videoPreviewLayer: videoPreviewLayer,
                    edge: UIRectEdge.left,
                   thickness: CGFloat(maskThicknessLeftRight))
        addBorder(  videoPreviewLayer: videoPreviewLayer,
                    edge: UIRectEdge.right,
                    thickness: CGFloat(maskThicknessLeftRight))
    }
    
    
    func addBorder( videoPreviewLayer: AVCaptureVideoPreviewLayer,
                    edge: UIRectEdge,
                    thickness: CGFloat) {
        
        let color = UIColor(
            red: 211.0/255.0,
            green: 211.0/255.0,
            blue: 211.0/255.0,
            alpha : 0.8 )
        
        let border = CALayer();
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect(x: 0, y: 0, width: (videoPreviewLayer.frame.width), height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect(x:0, y:(videoPreviewLayer.frame.height) - thickness, width:(videoPreviewLayer.frame.width), height:thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect(x:0, y:maskThicknessTopBottom, width: thickness, height: (videoPreviewLayer.frame.height) - maskThicknessTopBottom*2.0)
            break
        case UIRectEdge.right:
            border.frame = CGRect(x:videoPreviewLayer.frame.width - thickness, y: maskThicknessTopBottom, width: thickness, height:  (videoPreviewLayer.frame.height) - maskThicknessTopBottom*2.0)
            break
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        
        videoPreviewLayer.addSublayer(border)
    }

    
}
