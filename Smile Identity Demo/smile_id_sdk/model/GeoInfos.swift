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
    
    var geoPermissionGranted    : Bool = false;
    var latitude                : Double = 0.0;
    var longitude               : Double = 0.0;
    var altitude                : Double = 0.0;
    var accuracy                : Double = 0.0;
    var lastUpdate              : String = "";
    
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
