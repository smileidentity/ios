//
//  PartnerParams.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/22/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class PartnerParams: Codable {
    static let USER_ID     = "user_id";
    static let JOB_ID      = "job_id";
    static let JOB_TYPE    = "job_type"

    var userId                  = ""
    var jobId                   = ""
    var jobType                 = -1
    var additionalValues        = [String : String] ()

    enum CodingKeys: String, CodingKey
    {
        case userId
        case jobId
        case jobType
    }
    
    init() {}
    
    // Android code does not parcel additionalProperties
    init( userId : String, jobId : String, jobType : Int ){
        self.userId = userId
        self.jobId = jobId
        self.jobType = jobType
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.jobId = try container.decode(String.self, forKey: .jobId)
        self.jobType = try container.decode(Int.self, forKey: .jobType)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: CodingKeys.userId)
        try container.encode(jobId, forKey: CodingKeys.jobId)
        try container.encode(jobType, forKey: CodingKeys.jobType)
    }
    
    
    func describeContents() -> Int {
        return 0;
    }
    
    func additionalValue(name : String, value : String ) -> PartnerParams {
        additionalValues[name] = value
        return self
    }
    
    
    func clear() {
        userId = ""
        jobId = ""
        jobType = -1
        additionalValues = [String : String] ()
    }
    
    func fromJsonDict( dict : Dictionary<String,Any>) -> PartnerParams {
        for (key, val) in dict {
            
            if( key == PartnerParams.USER_ID ) {
                userId = val as! String
            }
            else if( key == PartnerParams.JOB_ID ){
                jobId = val as! String
            }
            else if( key == PartnerParams.JOB_TYPE ){
                jobType = val as! Int
            }
            else{
                // set additional values,
                // if any are present in the json
                additionalValues[key] = val as? String
            }
            
        } // for
    }
    
    
    func fromJsonString( jsonFormattedString : String ) -> PartnerParams? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            let jsonUtils = JsonUtils()
            
            let dict = jsonUtils.jsonFormattedStringToDict(
                jsonFormattedString )
            
            fromJsonDict(dict: dict!)
            
        }
        
        return self
    }
    
    
    
    /* Note that in the original Android code, write to parcel does not
        include the additionalValues member variable,
        but toJsonString() does. */
    
    func toJsonDict() -> Dictionary<String,Any> {
        
        // Create a dictionary
        var dict = [String: Any]()
        dict[PartnerParams.USER_ID] = userId
        dict[PartnerParams.JOB_ID] = jobId
        dict[PartnerParams.JOB_TYPE] = jobType
        
        /* additionalvalues are simply added into the
         rather than as an array */
        for( key, value ) in additionalValues {
            dict[key] = value
        }
        
        return dict
    }
    
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()

        return jsonUtils.dictToJsonFormattedString(dict: toJsonDict())
        
    }
    
 
}
