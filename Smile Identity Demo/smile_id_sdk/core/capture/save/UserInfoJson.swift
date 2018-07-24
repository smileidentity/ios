//
//  UserInfoJson] = swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/30/18] =
//  Copyright © 2018 Smile Identity] =  All rights reserved] =
//

import Foundation

class UserInfoJson{
    
    static let KEY_JSON_VERIFIED        : String = "isVerifiedProcess"
    static let KEY_JSON_NAME            : String = "name"
    static let KEY_JSON_FB_USER_ID      : String = "fbUserID"
    static let KEY_JSON_FIRST_NAME      : String = "firstName"
    static let KEY_JSON_LAST_NAME       : String = "lastName"
    static let KEY_JSON_GENDER          : String = "gender"
    static let KEY_JSON_EMAIL           : String = "email"
    static let KEY_JSON_PHONE           : String = "phone"
    static let KEY_JSON_COUNTRY_CODE    : String = "countryCode"
    static let KEY_JSON_COUNTRY_NAME    : String = "countryName"
    
    var isVerifyProcess     : Bool = false
    var userName            : String = ""
    var fbUserId            : String = ""
    var fbUserFirstName     : String = ""
    var fbUserLastName      : String = ""
    var fbUserGender        : String = ""
    var fbUserEmail         : String = ""
    var fbUserPhoneNumber   : String = ""
    var countryCode         : String = ""
    var countryName         : String = ""
  
  
    init() {}
    
    init ( isVerifyProcess  : Bool,
           userName         : String,
           fbUserId         : String,
           fbUserFirstName  : String,
           fbUserLastName   : String,
           fbUserGender     : String,
           fbUserEmail      : String,
           fbUserPhoneNumber : String,
           countryCode      : String,
           countryName      : String ) {
        self.isVerifyProcess = isVerifyProcess;
        self.userName = userName;
        self.fbUserId = fbUserId;
        self.fbUserFirstName = fbUserFirstName;
        self.fbUserLastName = fbUserLastName;
        self.fbUserGender = fbUserGender;
        self.fbUserEmail = fbUserEmail;
        self.fbUserPhoneNumber = fbUserPhoneNumber;
        self.countryCode = countryCode;
        self.countryName = countryName;
    }
    
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> UserInfoJson? {
        let jsonUtils = JsonUtils()
        
        isVerifyProcess = jsonUtils.getBool(dict:dict,
            key: UserInfoJson.KEY_JSON_VERIFIED,
            defaultVal : false )
        
        userName = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_NAME,
            defaultVal : "" )
        
        fbUserId = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_FB_USER_ID,
            defaultVal : "" )
        
        fbUserFirstName = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_FIRST_NAME,
            defaultVal : "" )
            
        
        fbUserLastName = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_LAST_NAME,
            defaultVal : "" )
        
        fbUserGender = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_GENDER,
            defaultVal : "" )
        
        fbUserEmail = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_EMAIL,
            defaultVal : "" )
        
        fbUserPhoneNumber = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_PHONE,
            defaultVal : "" )
        
        countryCode = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_COUNTRY_CODE,
            defaultVal : "" )
        
        countryName = jsonUtils.getString(dict:dict,
            key: UserInfoJson.KEY_JSON_COUNTRY_NAME,
            defaultVal : "" )

        return self
     }
    
    func fromJsonString( jsonFormattedString : String ) -> UserInfoJson? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            let jsonUtils = JsonUtils()
            
            let dict = jsonUtils.jsonFormattedStringToDict(
                jsonFormattedString )
            
            return fromJsonDict(dict: dict!)
        }
  
    }
    
    
    
    
    func toJsonDict() -> Dictionary<String,Any> {
        let jsonUtils = JsonUtils()
        
        // Create a dictionary
        var dict = [String: Any]()
        
        jsonUtils.putBool( dict: &dict, key: UserInfoJson.KEY_JSON_VERIFIED,
            val: isVerifyProcess )
        
        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_NAME,
            val: userName )
        
        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_FB_USER_ID,
            val: fbUserId )
        
        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_FIRST_NAME,
            val: fbUserFirstName )

        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_LAST_NAME,
            val: fbUserLastName )
 
        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_GENDER,
            val: fbUserGender )
        
        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_EMAIL,
            val: fbUserEmail )
        
        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_PHONE,
            val: fbUserPhoneNumber )
        
        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_COUNTRY_CODE,
            val: countryCode )

        jsonUtils.putString( dict: &dict, key: UserInfoJson.KEY_JSON_COUNTRY_NAME,
            val: countryName )
        
        return dict
    }
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
     
    
}
