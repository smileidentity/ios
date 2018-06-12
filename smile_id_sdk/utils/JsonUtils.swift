//
//  JsonUtils.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class JsonUtils {
    
    /*
     Convert json formatted string to dictionary
    */
    func jsonFormattedStringToDict(_ jsFormattedString : String) -> [String:Any]? {
        var dict = [String:Any] ()
        do {
            // First convert string to byte data
            if let data = jsFormattedString.data(using: String.Encoding.utf8) {
            
                // Now convert data to dictionary
                try dict = JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
 
            }
        } catch let error as NSError {
            let logger = SILog()
            logger.SIPrint(logOutput: error.localizedDescription )
        }
        
        return dict
    }
    
    func dictToJsonFormattedString( dict : [ String:Any ] ) -> String {
        var jsonFormattedString : String = "{}"
        do{
            // First, convert dict to byte data
            let jsData = try JSONSerialization.data(withJSONObject: dict, options: [] )
        
            // Now create string from byte data
            jsonFormattedString = String(data: jsData, encoding: .ascii)!
            
        } catch let error as NSError {
            let logger = SILog()
            logger.SIPrint(logOutput: error.localizedDescription )
        }
        
        return jsonFormattedString
       
    }
    
    
    
    
    /* If key does not exist, then Dictionary always returns nil */
    func getString( dict : [String : Any],
                    key : String ) -> String? {
        return dict[key] as? String
    }
    
    func putString( dict :  inout [String : Any],
                    key : String,
                    val : String ) {
        dict[key] = val
    }
    
    func getInt( dict : [String : Any],
                 key : String ) -> Int? {
        let defaultVal : Int = 0
        if let val = dict[key]{
            return val as? Int
        }
        else{
            return defaultVal
        }
    }
    func putInt( dict :  inout [String : Any],
                    key : String,
                    val : Int ) {
        dict[key] = val
    }
    
    
    func getFloat( dict : [String : Any],
                 key : String ) -> Float? {
        let defaultVal : Float = 0.0
        if let val = dict[key]{
            return val as? Float
        }
        else{
            return defaultVal
        }
    }
    func putFloat( dict :  inout [String : Any],
                 key : String,
                 val : Float ) {
        dict[key] = val
    }

    
    func getInt64( dict : [String : Any],
                   key : String ) -> Int64? {
        let defaultVal : Int64 = 0
        if let val = dict[key]{
            return val as? Int64
        }
        else{
            return defaultVal
        }
    }
    func putInt64( dict :  inout [String : Any],
                 key : String,
                 val : Int64 ) {
        dict[key] = val
    }
    
    func getBool( dict : [String : Any],
                  key : String ) -> Bool? {
        let defaultVal = false
        if let val = dict[key]{
            return val as? Bool
        }
        else{
            return defaultVal
        }
    }
    func putBool( dict :  inout [String : Any],
                   key : String,
                   val : Bool ) {
        dict[key] = val
    }
    
    func getArray( dict : [String : Any],
                   key : String ) -> [Any]? {
        let defaultVal = [Any]()
        if let val = dict[key]{
            return val as? [Any]
        }
        else {
            return defaultVal
        }
    }
    
    func putArray( dict :  inout [String : Any],
                  key : String,
                  val : [Any] ) {
        dict[key] = val
    }
    

    
}
