//
//  FullFrameInfo.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class FullFrameInfo {
    static let KEY_DATE_TIME        : String = "dateTime"
    static let KEY_FILENAME         : String = "fileName"
    static let KEY_IMAGE_LENGTH     : String = "imageLength"
    static let KEY_IMAGE_WIDTH      : String = "imageWidth"
    static let KEY_ORIENTATION      : String = "orientation"
    static let KEY_SMILE_VALUE      : String = "smileValue"

    
    var orientation     :   Int = 0
    var imageLength     :   String = ""
    var imageWidth      :   String = ""
    var dateTime        :   String = ""
    var smileValue      :   Double = 0.0
    var fileName        :   String = ""
    
    init(){}
    
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
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> FullFrameInfo? {
        let jsonUtils = JsonUtils()
        dateTime = jsonUtils.getString(dict:dict,
            key: FullFrameInfo.KEY_DATE_TIME,
            defaultVal : "" )
        
        fileName = jsonUtils.getString(dict:dict,
            key: FullFrameInfo.KEY_FILENAME,
            defaultVal : "" )
        
        imageLength = jsonUtils.getString(dict:dict,
            key: FullFrameInfo.KEY_IMAGE_LENGTH,
            defaultVal : "" )
        
        imageWidth = jsonUtils.getString(dict:dict,
            key: FullFrameInfo.KEY_IMAGE_WIDTH,
            defaultVal: "" )
        
        orientation = jsonUtils.getInt(dict:dict,
            key: FullFrameInfo.KEY_ORIENTATION,
            defaultVal: 0 )
        
        smileValue = jsonUtils.getDouble(dict:dict,
            key: FullFrameInfo.KEY_SMILE_VALUE,
            defaultVal : 0.0 )

        return self
       }
    
    func fromJsonString( jsonFormattedString : String ) -> FullFrameInfo? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            let jsonUtils = JsonUtils()
            
            let dict = jsonUtils.jsonFormattedStringToDict(
                jsonFormattedString )
            return fromJsonDict( dict: dict! )
            
        }
 
    }
    
    

    
    func toJsonDict() -> Dictionary<String,Any> {
        
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
        
        jsonUtils.putString( dict: &dict, key: FullFrameInfo.KEY_DATE_TIME,
                             val: dateTime )
        
        jsonUtils.putString( dict: &dict, key: FullFrameInfo.KEY_FILENAME,
                             val: fileName )

        jsonUtils.putString( dict: &dict, key: FullFrameInfo.KEY_IMAGE_LENGTH,
                             val: imageLength )

        jsonUtils.putString( dict: &dict, key: FullFrameInfo.KEY_IMAGE_WIDTH,
            val: imageWidth )
        
        jsonUtils.putInt( dict: &dict, key: FullFrameInfo.KEY_ORIENTATION,
                          val: orientation )
        
        jsonUtils.putDouble( dict: &dict, key: FullFrameInfo.KEY_SMILE_VALUE,
                             val: smileValue )
        return dict
    }
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
    
}
