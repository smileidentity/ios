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
  
    let jsonUtils           = JsonUtils()

    
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
    
    
    func toJsonDict() -> Dictionary<String,Any> {
        
        // Create a dictionary
        var dict = [String: Any]()
        dict[UserInfoJson.KEY_JSON_VERIFIED] = isVerifyProcess
        dict[UserInfoJson.KEY_JSON_NAME] = userName
        dict[UserInfoJson.KEY_JSON_FB_USER_ID] = fbUserId
        dict[UserInfoJson.KEY_JSON_FIRST_NAME] = fbUserFirstName
        dict[UserInfoJson.KEY_JSON_LAST_NAME] = fbUserLastName
        dict[UserInfoJson.KEY_JSON_GENDER] = fbUserGender
        dict[UserInfoJson.KEY_JSON_EMAIL] = fbUserEmail
        dict[UserInfoJson.KEY_JSON_PHONE] = fbUserPhoneNumber
        dict[UserInfoJson.KEY_JSON_COUNTRY_CODE] = countryCode
        dict[UserInfoJson.KEY_JSON_COUNTRY_NAME] = countryName

        return dict
    }
    
    func toJsonString() -> String {
        
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )

    }
     
    
}
