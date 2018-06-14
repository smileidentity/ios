//
//  SecurityCaps.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SecurityCaps {
    static let KEY_AES_CAPABLE       : String = "AESCapable"
    static let KEY_RSA_CAPABLE       : String = "RSACapable"
    
    
    var AESCapable : Bool = false;
    var RSACapable : Bool = false;
    
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> SecurityCaps? {
        let jsonUtils = JsonUtils()
        
        AESCapable = jsonUtils.getBool(dict:dict,
                                       key: SecurityCaps.KEY_AES_CAPABLE )!
        RSACapable = jsonUtils.getBool(dict:dict,
                                       key: SecurityCaps.KEY_RSA_CAPABLE)!

        
    }
    
    func fromJsonString( jsonFormattedString : String ) -> SecurityCaps? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            let jsonUtils = JsonUtils()
            
            let dict = jsonUtils.jsonFormattedStringToDict(
                jsonFormattedString )
            return fromJsonDict( dict: dict! )
            
        }
        
        return self
    }
    
   
    
    func toJsonDict() -> Dictionary<String,Any> {
        
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
        
        jsonUtils.putBool( dict: &dict, key: SecurityCaps.KEY_AES_CAPABLE,
                          val: AESCapable )
        
        jsonUtils.putBool( dict: &dict, key: SecurityCaps.KEY_RSA_CAPABLE,
                           val: RSACapable )
     
        return dict
    }
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
        
    }
    
    
}
