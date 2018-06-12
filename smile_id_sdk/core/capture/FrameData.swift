//
//  FrameData.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/8/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class FrameData : NSObject {
    var frameNum    : Int?
    var frameBytes  : Data?
    var smileValue  : Double = 0.0
    var dateTime    : String?
    
    
    var left        : Int?
    var top         : Int?
    var right       : Int?
    var bottom      : Int?
    var width       : Int?
    var height      : Int?
    var exif        : Int?
    
    init(   frameNum    : Int,
            frameBytes  : Data,
            smileValue  : Double,
            dateTime    : String,
            left        : Int,
            top         : Int,
            right       : Int,
            bottom      : Int,
            width       : Int,
            height      : Int,
            exif        : Int
          ) {
        self.frameNum = frameNum
        self.frameBytes = frameBytes
        self.smileValue = smileValue
        self.dateTime = dateTime
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
        self.width = width
        self.height = height
        self.exif = exif
        
    }
    
    func toString() -> String {
        var s = "frameNum = "
        s += String(frameNum!)
        s += "\nSmile Value = "
        s += String(smileValue)
        s += "\nDateTime = "
        s += dateTime!
        s += "\nLeft = "
        s += String(left!)
        s += "\nRight = "
        s += String(right!)
        s += "\nTop = "
        s += String(top!)
        s += "\nBottom = "
        s += String(bottom!)
        s += "\nWidth = "
        s += String(width!)
        s += "\nHeight = "
        s += String(height!)
        s += "\nExif = "
        s += String(exif!)
        
        
        
        return s
    }
    
    
    

}
