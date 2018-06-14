//
//  APIVersion.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

/*
 Smile ID SDK version information
*/
class APIVersion {
    static let KEY_BUILD_NUMBER       : String = "buildNumber"
    
    static let KEY_MAJOR_VERSION      : String = "majorVersion"
    
    static let KEY_MIN_VERSION          : String = "minorVersion"

    static let MINOR_VERSION    : Int = 1;
    static let MAJOR_VERSION    : Int = 1;
    static let BUILD_NUMBER     : Int = 2;
    var minorVersion = MINOR_VERSION;
    var majorVersion = MAJOR_VERSION;
    var buildNumber = BUILD_NUMBER;
    

    func fromJsonDict( dict : Dictionary<String,Any> ) -> APIVersion? {
        let jsonUtils = JsonUtils()
        
        minorVersion = jsonUtils.getInt(dict:dict,
                                        key: APIVersion.KEY_MIN_VERSION )!
        majorVersion = jsonUtils.getInt(dict:dict,
                                        key: APIVersion.KEY_MAJOR_VERSION )!
        buildNumber = jsonUtils.getInt( dict:dict,
                                        key: APIVersion.KEY_BUILD_NUMBER )!
        
        return self
    }
    
    func fromJsonString( jsonFormattedString : String ) -> APIVersion? {
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
        
        jsonUtils.putInt( dict: &dict, key: APIVersion.KEY_BUILD_NUMBER,
                          val: buildNumber )
        
        jsonUtils.putInt( dict: &dict, key: APIVersion.KEY_MAJOR_VERSION,
                          val: majorVersion )
        
        jsonUtils.putInt( dict: &dict, key: APIVersion.KEY_MIN_VERSION,
                          val: minorVersion )
        
        return dict
    }
    
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
}
