//
//  CameraSize.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/11/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class PreviewSize {
    
    static let KEY_WIDTH       : String = "width"
    static let KEY_HEIGHT      : String = "height"

    
    var width   : Int = 0
    var height  : Int = 0
    
    init() {
        self.width = 0
        self.height = 0
    }
    
    init( width : Int, height : Int ){
        self.width = width
        self.height = height
    }
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> PreviewSize? {
        let jsonUtils = JsonUtils()
        
        width = jsonUtils.getInt(dict:dict,
                                 key: PreviewSize.KEY_WIDTH,
                                 defaultVal : 0 )
        
        height = jsonUtils.getInt(dict:dict,
                                  key: PreviewSize.KEY_HEIGHT,
                                  defaultVal : 0 )
        
        return self
        
    }
    
    func fromJsonString( jsonFormattedString : String ) -> PreviewSize? {
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
        
        jsonUtils.putInt( dict: &dict, key: PreviewSize.KEY_WIDTH,
            val: width )
        jsonUtils.putInt( dict: &dict, key: PreviewSize.KEY_HEIGHT,
            val: height )
 
        return dict
    }
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
    
    
}
