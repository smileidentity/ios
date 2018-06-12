//
//  FullFrameInfo.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class FullFrameInfo {
    var orientation     :   Int?
    var imageLength     :   String?
    var imageWidth      :   String?
    var dateTime        :   String?
    var smileValue      :   Double?
    var fileName        :   String?
    
    init( smileValue    : Double,
          fileName      : String,
          dateTime      : String ){
        
        self.smileValue = smileValue
        self.fileName = fileName
        self.dateTime = dateTime
        
    }
    
    func setExifData( orientation   : Int,
                      imageWidth    : Int,
                      imageLength   : Int ) {
        // Orientation of pic Clicked with Device Camera, it needs to be turned to zero degree
        self.orientation = orientation;  // old code has this hardcoded
        self.imageWidth = String( imageWidth )
        self.imageLength = String( imageLength )
    }

    
    
}
