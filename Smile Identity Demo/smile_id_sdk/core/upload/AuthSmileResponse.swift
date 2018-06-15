//
//  AuthSmileResponse.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/24/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class AuthSmileResponse : JsonResponse {
    
    static let KEY_SUCCESS         : String    = "success"
    static let KEY_TIMESTAMP       : String    = "timestamp"
    static let KEY_SEC             : String    = "sec_key"
    static let KEY_CALLBACK_URL    : String    = "callback_url"
    static let KEY_SMILE_CLIENT_ID : String    = "smile_client_id"
    static let KEY_ERRORS          : String    = "errors"
    static let KEY_USER_ERRORS     : String    = "user_errors"
    static let KEY_PARTNER_PARAMS  : String    = "partner_params"
    
    var success         : Bool?
    var errors          = [String]()
    var userErrors      = [String]()
    
    /* TimeInterval is an alias for Double */
    // var timestamp       : TimeInterval?
    var timestamp       : Int64?  // server returns int64 utc
    var secKey          : String?
    var callbackUrl     : String?
    var smileClientId   : String?
    var partnerParams   = PartnerParams();
    
    /* Note that in Android code additionalProperties is not included in the json */
    var additionalProperties        = [String : String] ()
    
    let jsonUtils       = JsonUtils()
   
    /* Initialize from json string */
    override func fromJsonString( jsonFormattedString : String ) -> AuthSmileResponse? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            rawJsonString = jsonFormattedString
            let dict = jsonUtils.jsonFormattedStringToDict( jsonFormattedString )
            setPartnerParamsValues(dict: dict!)
            setJobResponseValues(dict: dict!)
        }
        
        return self
    }
    
    func setPartnerParamsValues( dict : [String : Any] ) {
        if let jsonParterParamsString = dict[AuthSmileResponse.KEY_PARTNER_PARAMS] {
            let partnerParamsDict = jsonParterParamsString as! [String : Any]
                partnerParams.userId = jsonUtils.getString(dict: partnerParamsDict, key: PartnerParams.USER_ID )!
                partnerParams.jobId = jsonUtils.getString(dict: partnerParamsDict, key: PartnerParams.JOB_ID )!
                partnerParams.jobType = jsonUtils.getInt(dict: partnerParamsDict, key: PartnerParams.JOB_TYPE)!
         }
    }
    
    func setJobResponseValues( dict : [String : Any] ){
        success = jsonUtils.getBool(dict: dict, key: AuthSmileResponse.KEY_SUCCESS )
        timestamp = jsonUtils.getInt64(dict:dict, key: AuthSmileResponse.KEY_TIMESTAMP )
        secKey = jsonUtils.getString(dict:dict, key: AuthSmileResponse.KEY_SEC)
        callbackUrl = jsonUtils.getString(dict:dict,key: AuthSmileResponse.KEY_CALLBACK_URL )
        smileClientId = jsonUtils.getString(dict:dict,key: AuthSmileResponse.KEY_SMILE_CLIENT_ID )
        errors = jsonUtils.getArray(dict: dict, key: AuthSmileResponse.KEY_ERRORS ) as! [String]
        userErrors = jsonUtils.getArray(dict: dict, key: AuthSmileResponse.KEY_USER_ERRORS ) as! [String]

    }
    
}
