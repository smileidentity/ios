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
    
  
    
    func getDict( dict:[String : Any],
                  key : String,
                  defaultVal : Dictionary<String,Any>) -> Dictionary<String,Any> {
        
        let val = dict[key]
        if( val == nil ){
            return defaultVal
        }
        else{
            return jsonFormattedStringToDict( val! as! String )!
        }
    }
    
    func putDict( dict : inout [String : Any],
                  key : String,
                  val : Dictionary<String,Any> ){
        dict[key] = dictToJsonFormattedString( dict: val )
    }
    
    
    
     func getString( dict        : [String : Any],
                    key         : String,
                    defaultVal  : String ) -> String {
        let val = dict[key]
        if( val == nil ){    /* If key does not exist, then Dictionary always returns nil */
            return defaultVal
        }
        else{
            return val! as! String
        }
    }
    
    func putString( dict :  inout [String : Any],
                    key : String,
                    val : String ) {
        dict[key] = val
    }
    
    func getInt( dict       : [String : Any],
                 key        : String,
                 defaultVal : Int ) -> Int {
        let val = dict[key] 
        if( val == nil ) {
            return defaultVal
        }
        else{
            return val! as! Int
        }
    }
    func putInt( dict :  inout [String : Any],
                    key : String,
                    val : Int ) {
        dict[key] = val
    }
    
    
    func getFloat( dict     : [String : Any],
                 key        : String,
                 defaultVal : Float ) -> Float {
       
        let val = dict[key]
        if ( val == nil ) {
            return defaultVal
        }
        else{
            return val! as! Float
        }
    }
    func putFloat( dict :  inout [String : Any],
                 key : String,
                 val : Float ) {
        dict[key] = val
    }
    
    
    
    func getDouble( dict        : [String : Any],
                   key          : String,
                   defaultVal   : Double ) -> Double {
        let val = dict[key]
        if( val == nil ){
            return defaultVal
        }
        else{
            return val! as! Double
        }
    }
    func putDouble( dict :  inout [String : Any],
                   key : String,
                   val : Double ) {
        dict[key] = val
    }

    
    func getInt64( dict : [String : Any],
                   key : String,
                   defaultVal : Int64 ) -> Int64 {
        let val = dict[key]
        if( val == nil ){
            return defaultVal
        }
        else{
            return val! as! Int64
        }
    }
    func putInt64( dict :  inout [String : Any],
                 key : String,
                 val : Int64 ) {
        dict[key] = val
    }
    
    func getBool( dict          : [String : Any],
                  key           : String,
                  defaultVal    : Bool ) -> Bool {
        let val = dict[key]
        if( val == nil ){
            return defaultVal
        }
        else{
            return val! as! Bool
        }
    }
    func putBool( dict :  inout [String : Any],
                   key : String,
                   val : Bool ) {
        dict[key] = val
    }
    
    func getArray( dict         : [String : Any],
                   key          : String,
                   defaultVal   : [Any] ) -> [Any] {
        let val = dict[key]
        if ( val == nil ){
            return defaultVal
        }
        else {
            return val! as! [Any]
        }
    }
    
    func putArray( dict :  inout [String : Any],
                  key : String,
                  val : [Any] ) {
        dict[key] = val
    }
    
 
    
}
