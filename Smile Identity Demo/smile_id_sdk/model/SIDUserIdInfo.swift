//
//  SIDUserIdInfo.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/29/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDUserIdInfo {

    static let FIRST_NAME      : String = "first_name";
    static let LAST_NAME       : String = "last_name";
    static let MIDDLE_NAME     : String = "middle_name";
    static let COUNTRY         : String = "country";
    static let ID_TYPE         : String = "id_type";
    static let ID_NUMBER       : String = "id_number";
    static let ENTERED         : String = "entered";

    
    var firstName               : String = "";
    var lastName                : String = "";
    var middleName              : String = "";
    var country                 : String = "";
    var idType                  : String = "";
    var idNumber                : String = "";
    var additionalProperties    = [String : String] ()
 
    var currentHash             : String = ""

    
    init() {
         currentHash = toString()
    }
    
    func additionalValue( name : String, value : String ) -> SIDUserIdInfo {
        additionalProperties[name] = value
        return self;
    }
    

    
    
    func dataEntered() -> Bool {
        if( currentHash == toString() ){
            return false
        }
        else{
            return true
        }
    }
    
    func additionalPropertiesToString() -> String {
        var s : String = ""
        for( key, value ) in additionalProperties {
            s = s + key + ":" + value
        }
        return s
    }
    func toString() -> String {
        
        let sFirstName = "firstName='" + firstName + "'"
        let sLastName =  ", lastName='" + lastName + "'"
        let sMidName = ", middleName='" + middleName + "'"
        let sCountry =   ", country='" + country + "'"
        let sIdType = ", idType='" + idType + "'"
        let sIdNumber = ", idNumber='" + idNumber + "'"
        let sAdditionalProperties = ", additionalEntries='" + additionalPropertiesToString() + "'"
    
        return "SIDUserIdInfo{" +
            sFirstName +
            sLastName +
            sMidName +
            sCountry +
            sIdType +
            sIdNumber +
            sAdditionalProperties +
            "}";
    }
    
    
    func fromJsonString( jsonFormattedString : String ) -> SIDUserIdInfo? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            let jsonUtils = JsonUtils()
            
            let dict = jsonUtils.jsonFormattedStringToDict(
                jsonFormattedString )
            
            
            for (key, val) in dict! {
                
                if( key == SIDUserIdInfo.FIRST_NAME ) {
                    firstName = val as! String
                }
                else if( key ==  SIDUserIdInfo.MIDDLE_NAME ){
                    middleName = val as! String
                }
                else if( key == SIDUserIdInfo.LAST_NAME ){
                    lastName = val as! String
                }
                else if( key == SIDUserIdInfo.COUNTRY ){
                    country = val as! String
                }
                else if( key == SIDUserIdInfo.ID_TYPE ){
                    idType = val as! String
                }
                else if( key == SIDUserIdInfo.ID_NUMBER ){
                    idNumber = val as! String
                }
                else if( key == SIDUserIdInfo.ENTERED ){
                    let sEntered = jsonUtils.getString(dict:dict!,
                    key: SIDUserIdInfo.ENTERED )!
                    
                    if( sEntered == "true" ){
                        currentHash = toString()
                    }
                    else {
                        currentHash = ""
                    }
                }
                else{
                    // set additional props,
                    // if any are present in the json
                    additionalProperties[key] = val as? String
                }
        }
        
        return self
    }
    
    
    
    
    func toJsonDict( useAdditionalProps : Bool ) -> Dictionary<String,Any> {
        
        // Create a dictionary
        var dict = [String: Any]()
        let jsonUtils = JsonUtils()
        jsonUtils.putString( dict: &dict, key: SIDUserIdInfo.FIRST_NAME,
            val:firstName )
        
        jsonUtils.putString( dict: &dict, key: SIDUserIdInfo.MIDDLE_NAME,
            val:middleName )

        jsonUtils.putString( dict: &dict, key: SIDUserIdInfo.LAST_NAME,
            val:lastName )

        jsonUtils.putString( dict: &dict, key: SIDUserIdInfo.COUNTRY,
            val:country )

        jsonUtils.putString( dict: &dict, key: SIDUserIdInfo.ID_TYPE,
            val:idType )

        jsonUtils.putString( dict: &dict, key: SIDUserIdInfo.ID_NUMBER,
            val:idNumber )
        
        
        if( dataEntered() ){
            jsonUtils.putString( dict: &dict, key: SIDUserIdInfo.ENTERED,
                val:"true" )
        }
        else{
            jsonUtils.putString( dict: &dict, key: SIDUserIdInfo.ENTERED,
                val:"false" )
        }
        
        if( useAdditionalProps ){
            for( key, value ) in additionalProperties {
                dict[key] = value
            }
            
        }
        
        return dict
    }
    
    func toJsonString( useAdditionalProps : Bool ) -> String {
        let jsonUtils = JsonUtils()

        return jsonUtils.dictToJsonFormattedString(dict: toJsonDict(useAdditionalProps: useAdditionalProps))

        
    }
    
    
    
}
    

