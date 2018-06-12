//
//  CaptureIDCardVideoPreview.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/16/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class CaptureIDCardVideoPreview : VideoPreviewView {
    
    var idCardTouchDelegate : IDCardTouchDelegate?
    var touchCircleLayer    : CAShapeLayer?
    
    
    var touchX : CGFloat?
    var touchY : CGFloat?
    
    // TODO = make these constants
    let maskThicknessLeftRight      : CGFloat = 80.0
    let maskThicknessTopBottom      : CGFloat = 50.0
    
    
    let touchColor = UIColor(
        red: 255.0/255.0,
        green: 255.0/255.0,
        blue: 255.0/255.0,
        alpha : 0.4 )
     
    
    func setupTouchRecognizer( idCardTouchDelegate : IDCardTouchDelegate ) {
        self.idCardTouchDelegate = idCardTouchDelegate
    
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGestureRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(tapGestureRecognizer)
    }
  
    @objc func handleTap(_ sender:UITapGestureRecognizer){
        if sender.state == .ended {
            let cgPoint = sender.location(in: self )
            
            // check if point is within mask
            let x = cgPoint.x
            let y = cgPoint.y
            if( x >  maskThicknessLeftRight &&
                x <= bounds.width - maskThicknessLeftRight &&
                y > maskThicknessTopBottom && y <= bounds.height - maskThicknessTopBottom ){
                
                touchX = x
                touchY = y
                setNeedsDisplay()
                
                idCardTouchDelegate?.onHandleTouch()

            }
            
        }
    }
    
    func removeTouchCircle() {
        touchCircleLayer?.removeFromSuperlayer()
    }

    
    func setTouch( touchX : CGFloat, touchY : CGFloat ){
        self.touchX = touchX
        self.touchY = touchY
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect)
    {
        if( touchX == nil || touchY == nil ) {
            return
        }
        let cgTouchRect = CGRect(x: touchX!, y: touchY!, width: 50.0, height: 50.0)
        let touchPath = UIBezierPath(ovalIn: cgTouchRect)
        touchCircleLayer = CAShapeLayer()
        touchCircleLayer?.path = touchPath.cgPath
        touchCircleLayer?.fillColor = UIColor.clear.cgColor
        touchCircleLayer?.strokeColor = touchColor.cgColor
        touchCircleLayer?.lineWidth = 5.0

        layer.addSublayer(touchCircleLayer!)
        
    }
}
