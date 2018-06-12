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
    var isAuthenticationMode: Bool = false

    
    init (      jobType : Int,
                userId : String,
                isIdPresent : Bool,
                isAuthenticationMode : Bool ) {
        self.jobType = jobType;
        self.isIdPresent = isIdPresent;
        self.userId = userId;
        self.isAuthenticationMode = isAuthenticationMode;

    }
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
        
        dict[AuthSmileRequestJson.KEY_JSON_AUTH_TOKEN] = "1"
        if( isAuthenticationMode ){
            dict[AuthSmileRequestJson.KEY_JSON_ENROLLMENT] = false
            dict[AuthSmileRequestJson.KEY_JSON_ID_PRESENT] = false
            dict[AuthSmileRequestJson.KEY_JSON_USER_ID] = userId
        }
        else{
            dict[AuthSmileRequestJson.KEY_JSON_ENROLLMENT] = true
            dict[AuthSmileRequestJson.KEY_JSON_ID_PRESENT] = isIdPresent
            dict[AuthSmileRequestJson.KEY_JSON_USER_ID] = "UNKNOWN"

        }
        if( jobType! > 0 ) {
            dict[AuthSmileRequestJson.KEY_JSON_JOB_TYPE] = String(jobType!)
        }
        
        dict[AuthSmileRequestJson.KEY_JSON_TIMESTAMP] = Int64(NSDate().timeIntervalSince1970 * 1000)
        
        
        return jsonUtils.dictToJsonFormattedString( dict : dict )
    }
    
}
