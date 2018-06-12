//
//  SIDUserIdInfo.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/29/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDUserIdInfo {
    static let SECTION_NAME    : String = "id_info";
    static let FIRST_NAME      : String = "first_name";
    static let LAST_NAME       : String = "last_name";
    static let MIDDLE_NAME     : String = "middle_name";
    static let COUNTRY         : String = "country";
    static let ID_TYPE         : String = "id_type";
    static let ID_NUMBER       : String = "id_number";
    static let ENTERED         : String = "entered";

    
    var firstName       : String = "";
    var lastName        : String = "";
    var middleName      : String = "";
    var country         : String = "";
    var idType          : String = "";
    var idNumber        : String = "";
    var additionalProperties        = [String : String] ()
 
    var currentHash     : String?

    
    init() {
         currentHash = toString()
    }
    
    func additionalValue( name : String, value : String ) -> SIDUserIdInfo {
        additionalProperties[name] = value
        return self;
    }
    
    func toJsonString() -> String {
        var jsString : String?
        var dict = [String: Any]()
        dict[SIDUserIdInfo.FIRST_NAME] = firstName
        dict[SIDUserIdInfo.MIDDLE_NAME] = middleName
        dict[SIDUserIdInfo.LAST_NAME] = lastName
        dict[SIDUserIdInfo.COUNTRY] = country
        dict[SIDUserIdInfo.ID_TYPE] = idType
        dict[SIDUserIdInfo.ID_NUMBER] = idNumber
        for( key, value ) in additionalProperties {
            dict[key] = value
        }
        
        if( dataEntered() ){
            dict[SIDUserIdInfo.ENTERED] = "true"
        }
        else{
            dict[SIDUserIdInfo.ENTERED] = "false"
        }
        
        let jsonUtils = JsonUtils()
        jsString = jsonUtils.dictToJsonFormattedString(dict: dict)
        
        return jsString!
        
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
    }
    

