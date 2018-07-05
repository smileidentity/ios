//
//  GeoInfos.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/23/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class GeoInfos {
    
    static let KEY_GEO_PERMISSION_GRANTED
        : String = "GeoPermissionGranted"
    static let KEY_LATITUDE         : String = "latitude"
    static let KEY_LONGITUDE        : String = "longitude"
    static let KEY_ALTITUDE         : String = "altitude"
    static let KEY_ACCURACY         : String = "accuracy"
    static let KEY_LAST_UPDATE      : String = "lastUpdate"
    static let EPSILON              = 0.0000001
    
    var geoPermissionGranted    : Bool = false;
    var latitude                : Double = 0.0;
    var longitude               : Double = 0.0;
    var altitude                : Double = 0.0;
    var accuracy                : Double = 0.0;
    var lastUpdate              : String = "";
    
    init() {}
    
    init( latitude      : Double,
          longitude     : Double,
          altitude      : Double,
          accuracy      : Double,
          lastUpdate    : String ) {
    
        self.latitude = latitude
        if( !isEqual( val1: latitude, val2: 0.0 )){
            self.longitude = longitude
            self.altitude = altitude
            self.accuracy = accuracy
            self.lastUpdate = lastUpdate
            self.geoPermissionGranted = true
        }
        
    }
    func isEqual( val1 : Double, val2 : Double ) -> Bool {
        return abs(val1 - val2) <= GeoInfos.EPSILON
    }
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> GeoInfos? {
        let jsonUtils = JsonUtils()
        geoPermissionGranted = jsonUtils.getBool(dict:dict,
                                        key: GeoInfos.KEY_GEO_PERMISSION_GRANTED,
                                        defaultVal : false )
        
        latitude = jsonUtils.getDouble(dict:dict,
                                    key: GeoInfos.KEY_LATITUDE,
                                    defaultVal : 0.0)
        
        longitude = jsonUtils.getDouble(dict:dict,
                                        key: GeoInfos.KEY_LONGITUDE,
                                        defaultVal : 0.0 )
        
        altitude = jsonUtils.getDouble(dict:dict,
                                       key: GeoInfos.KEY_ALTITUDE,
                                       defaultVal : 0.0 )
        
        accuracy = jsonUtils.getDouble(dict:dict,
                                       key: GeoInfos.KEY_ACCURACY,
                                       defaultVal : 0.0 )
        
        lastUpdate = jsonUtils.getString(dict:dict,
                                         key: GeoInfos.KEY_LAST_UPDATE,
                                         defaultVal : "")
        
        return self
    }
    
    func fromJsonString( jsonFormattedString : String ) -> GeoInfos? {
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

        // Create a dictionary
        var dict = [String: Any]()
        let jsonUtils = JsonUtils()
        jsonUtils.putBool( dict: &dict, key: GeoInfos.KEY_GEO_PERMISSION_GRANTED,
            val:geoPermissionGranted )
        
        jsonUtils.putDouble( dict: &dict, key: GeoInfos.KEY_LATITUDE,
            val:latitude )
        
        jsonUtils.putDouble( dict: &dict, key: GeoInfos.KEY_LONGITUDE,
            val:longitude )
        
        jsonUtils.putInt( dict: &dict, key: GeoInfos.KEY_ALTITUDE,
            val:Int(altitude ))
        
        jsonUtils.putDouble( dict: &dict, key: GeoInfos.KEY_ACCURACY,
            val:accuracy )
        
        jsonUtils.putString( dict: &dict, key: GeoInfos.KEY_LAST_UPDATE,
            val:lastUpdate )

        
        return dict
    }
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()

        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
        
    }
    

}
