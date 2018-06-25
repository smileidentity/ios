//
//  ImageProcessingCaps.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/12/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class ImageProcessingCaps {
    
    static let KEY_DEBUG_AFTER_CROP         : String = "debug_rotate_after_crop"
    static let KEY_DETECT_BLURRY_IMAGE      : String = "detectBlurryImage"
    static let KEY_DETECT_LOW_LIGHT         : String = "detectLowLight"
    static let KEY_ROTATE_IMAGES            : String = "rotate_images"
    
    var detectBlurryImage           : Bool = false
    var detectLowLight              : Bool = false
    var debug_rotate_after_crop     : Bool = true
    var rotate_images               : Bool = true
    
    
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> ImageProcessingCaps? {
        let jsonUtils = JsonUtils()
        debug_rotate_after_crop = jsonUtils.getBool(dict:dict,
            key: ImageProcessingCaps.KEY_DEBUG_AFTER_CROP,
            defaultVal: false )
        
        detectBlurryImage = jsonUtils.getBool(dict:dict,
            key: ImageProcessingCaps.KEY_DETECT_BLURRY_IMAGE,
            defaultVal: false )
        detectLowLight = jsonUtils.getBool(dict:dict,
            key: ImageProcessingCaps.KEY_DETECT_LOW_LIGHT,
            defaultVal: false )
        
        rotate_images = jsonUtils.getBool(dict:dict,
            key: ImageProcessingCaps.KEY_ROTATE_IMAGES,
            defaultVal : false )
        
        return self

    }
    
    func fromJsonString( jsonFormattedString : String ) -> ImageProcessingCaps? {
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
        // Build a dictionary,
        // then convert it to a formatted json string
        var dict = [String: Any]()
        let jsonUtils = JsonUtils()
        
        
        jsonUtils.putBool( dict: &dict, key: ImageProcessingCaps.KEY_DEBUG_AFTER_CROP,
                          val: debug_rotate_after_crop )
        
        jsonUtils.putBool( dict: &dict, key: ImageProcessingCaps.KEY_DETECT_BLURRY_IMAGE,
                           val: detectBlurryImage )
        
        jsonUtils.putBool( dict: &dict, key: ImageProcessingCaps.KEY_DETECT_LOW_LIGHT,
                           val: detectLowLight )
   
        jsonUtils.putBool( dict: &dict, key: ImageProcessingCaps.KEY_ROTATE_IMAGES,
        val: rotate_images )
        
        return dict
    }
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
}
