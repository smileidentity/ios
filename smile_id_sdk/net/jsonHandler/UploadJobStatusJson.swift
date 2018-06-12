//
//  UploadJobStatusJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/30/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class UploadJobStatusJson {
    
    static let KEY_JSON_SMILE_CLIENT_ID    : String = "smile_client_id"
    static let KEY_JSON_AUTH_TOKEN  : String = "auth_token";
    static let KEY_JSON_USER_ID     : String = "user_id";
    static let KEY_JSON_TIMESTAMP   : String = "timestamp";
    static let KEY_JSON_JOB_ID      : String = "job_id";
    
    var userId                      : String?
    var smileClientId               : String?
    var lastEnrolledJobId           : String?
    var jobId                       : String?
    var isAuthenticationMode        : Bool?
    
    let jsonUtils                   = JsonUtils()
    
    init( userId : String,
          smileClientId : String,
          lastEnrolledJobId : String,
          jobId : String,
          isAuthenticationMode : Bool ){
        
        self.userId = userId;
        self.smileClientId = smileClientId;
        self.lastEnrolledJobId = lastEnrolledJobId;
        self.isAuthenticationMode = isAuthenticationMode
        
   
    }
    
    func toJsonString() -> String {
        // Build a dictionary,
        // then convert it to a formatted json string
        var dict = [String: Any]()
        
        
        dict[UploadJobStatusJson.KEY_JSON_AUTH_TOKEN] = "1"
        dict[UploadJobStatusJson.KEY_JSON_USER_ID] = userId
        dict[UploadJobStatusJson.KEY_JSON_SMILE_CLIENT_ID] = smileClientId
         dict[UploadJobStatusJson.KEY_JSON_TIMESTAMP] = Int64(NSDate().timeIntervalSince1970 * 1000)
        if (isAuthenticationMode)! {
            dict[UploadJobStatusJson.KEY_JSON_JOB_ID] = lastEnrolledJobId
        } else {
            dict[UploadJobStatusJson.KEY_JSON_JOB_ID] = jobId
        }

        return jsonUtils.dictToJsonFormattedString( dict : dict )

    }
}
