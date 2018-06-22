//
//  UploadJobStatusJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/30/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class UploadJobStatus {
    
    static let KEY_JSON_SMILE_CLIENT_ID    : String = "smile_client_id"
    static let KEY_JSON_AUTH_TOKEN  : String = "auth_token";
    static let KEY_JSON_USER_ID     : String = "user_id";
    static let KEY_JSON_TIMESTAMP   : String = "timestamp";
    static let KEY_JSON_JOB_ID      : String = "job_id";
    
    var userId                      : String?
    var smileClientId               : String?
    var lastEnrolledJobId           : String?
    var jobId                       : String?
    var isEnrollMode                : Bool?
    
    let jsonUtils                   = JsonUtils()
    
    init( userId : String,
          smileClientId : String,
          lastEnrolledJobId : String,
          jobId : String,
          isEnrollMode : Bool ){
        
        self.userId = userId;
        self.smileClientId = smileClientId;
        self.lastEnrolledJobId = lastEnrolledJobId;
        self.isEnrollMode = isEnrollMode
        
   
    }
    
    
    func toJsonDict() -> Dictionary<String,Any> {
        
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
    
        jsonUtils.putString( dict: &dict,
                             key: UploadJobStatus.KEY_JSON_AUTH_TOKEN,
                             val: "1" )  // Android code hard-codes this as "1"
        
        jsonUtils.putString( dict: &dict,
                             key: UploadJobStatus.KEY_JSON_USER_ID,
                             val: userId! )
        
        jsonUtils.putString( dict: &dict,
                             key: UploadJobStatus.KEY_JSON_SMILE_CLIENT_ID,
                             val: smileClientId! )

        /* timestamp in milliseconds */
        jsonUtils.putInt64( dict: &dict,
                             key: UploadJobStatus.KEY_JSON_TIMESTAMP,
                             val: Int64(NSDate().timeIntervalSince1970 * 1000) )

        if( isEnrollMode! ){
            jsonUtils.putString( dict: &dict,
                                 key: UploadJobStatus.KEY_JSON_JOB_ID,
                                 val: jobId! )
        }
        else{
            // authentication mode
            jsonUtils.putString( dict: &dict,
                                 key: UploadJobStatus.KEY_JSON_JOB_ID,
                                 val: lastEnrolledJobId! )

        }
        
        return dict
    }
    
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }

}
