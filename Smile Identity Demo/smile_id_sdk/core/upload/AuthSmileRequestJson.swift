//
//  AuthSmileRequestJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/29/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class AuthSmileRequestJson {
    static let KEY_JSON_AUTH_TOKEN : String = "auth_token"
    static let KEY_JSON_ENROLLMENT : String = "enrollment"
    static let KEY_JSON_ID_PRESENT : String = "id_present"
    static let KEY_JSON_USER_ID    : String = "user_id"
    static let KEY_JSON_TIMESTAMP  : String = "timestamp"
    static let KEY_JSON_JOB_TYPE   : String = "job_type"
    
    var isIdPresent         : Bool?
    var userId              : String
    
    var jobType             : Int?
    var isEnrollMode        : Bool = true

    
    init (      jobType : Int,
                userId : String,
                isIdPresent : Bool,
                isEnrollMode : Bool ) {
        self.jobType = jobType;
        self.isIdPresent = isIdPresent;
        self.userId = userId;
        self.isEnrollMode = isEnrollMode;

    }
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
        
        jsonUtils.putString( dict: &dict,
            key: AuthSmileRequestJson.KEY_JSON_AUTH_TOKEN,
            val: "1" )
        jsonUtils.putBool( dict: &dict,
                           key: AuthSmileRequestJson.KEY_JSON_ENROLLMENT,
                           val: isEnrollMode )
        if( isEnrollMode ){

            jsonUtils.putBool( dict: &dict,
                               key: AuthSmileRequestJson.KEY_JSON_ID_PRESENT,
                               val: isIdPresent! )
        }
        else{
            jsonUtils.putBool( dict: &dict,
                               key: AuthSmileRequestJson.KEY_JSON_ID_PRESENT,
                               val: false )
            jsonUtils.putString( dict: &dict,
                                 key: AuthSmileRequestJson.KEY_JSON_USER_ID,
                                 val: userId )

   
        }
        if( jobType! > 0 ) {
            jsonUtils.putString( dict: &dict,
                                 key: AuthSmileRequestJson.KEY_JSON_JOB_TYPE,
                                 val: String(jobType!) )

        }
        
        jsonUtils.putInt64( dict: &dict,
                             key: AuthSmileRequestJson.KEY_JSON_TIMESTAMP,
                             val: Int64(NSDate().timeIntervalSince1970 * 1000 )
        )

        
        return jsonUtils.dictToJsonFormattedString( dict : dict )
    }
    
}
