//
//  StatusResponse.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class StatusResponse : JsonResponse {
    
    static let KEY_SUCCESS          : String     = "success"
    static let KEY_ERROR            : String     = "error"
    static let KEY_TIMESTAMP        : String     = "timestamp"
    static let KEY_SIGNATURE        : String     = "signature"
    static let KEY_JOB_COMPLETE     : String     = "job_complete"
    static let KEY_JOB_SUCCESS      : String     = "job_success"
    static let KEY_ERRORS           : String     = "errors"
    static let KEY_USER_ERRORS      : String     = "user_errors"
    static let KEY_PARTNER_PARAMS   : String     = "partner_params"
    
    static let KEY_RESULT           : String    = "result"
    static let KEY_RESULT_TEXT      : String    = "ResultText"
    static let KEY_RESULT_TYPE      : String    = "ResultType"
    static let KEY_SMILE_JOB_ID     : String    = "SmileJobID"
    static let KEY_JSON_VERSION     : String    = "JSONVersion"
    static let KEY_IS_FINAL_RESULT  : String    = "IsFinalResult"
    static let KEY_CONFIDENCE_VALUE : String    = "ConfidenceValue"
    static let KEY_MACHINE_RESULT   : String    = "IsMachineResult"
    
    var success         : Bool?
    var errors          = [String]()
    var userErrors      = [String]()
    
    /* TimeInterval is an alias for Double */
    // var timestamp       : TimeInterval?
    var timestamp       : Int64?  // server returns int64 utc
    
    var signature       : String?
    var jobComplete     : String?
    var jobSuccess      : String?
    var result          =  Result();
    var error           : String?
    var additionalProperties        = [String : String] ()
    
    let jsonUtils       = JsonUtils()

    func isJobComplete() -> Bool {
        if( jobComplete == "true" ){
            return true
        }
        else {
            return false
        }
    }
    
    func isJobSuccess() -> Bool {
        if( jobSuccess == "true" ){
            return true
        }
        else {
            return false
        }
    }
    
    /* Initialize from json string */
    override func fromJsonString( jsonFormattedString : String ) -> StatusResponse? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            rawJsonString = jsonFormattedString
            let dict = jsonUtils.jsonFormattedStringToDict( jsonFormattedString )
            setStatusDataResponse(dict: dict!)
            setResultValues(dict: dict!)
            setPartnerParamsValues(dict: dict!)
        }
        
        return self
    }
    
    func setStatusDataResponse( dict : [String : Any] ){
        error = jsonUtils.getString(dict:dict, key:StatusResponse.KEY_ERROR )
        success = jsonUtils.getBool( dict:dict, key:StatusResponse.KEY_SUCCESS )
        timestamp = jsonUtils.getInt64(dict:dict, key: StatusResponse.KEY_TIMESTAMP )
        signature = jsonUtils.getString( dict:dict, key: StatusResponse.KEY_SIGNATURE )
        jobComplete = jsonUtils.getString( dict:dict, key: StatusResponse.KEY_JOB_COMPLETE )
        jobSuccess = jsonUtils.getString( dict:dict, key: StatusResponse.KEY_JOB_SUCCESS )
        errors = jsonUtils.getArray(dict: dict, key: StatusResponse.KEY_ERRORS ) as! [String]
        userErrors = jsonUtils.getArray(dict: dict, key: StatusResponse.KEY_USER_ERRORS) as! [String]

    }
    
    
    func setResultValues( dict : [String : Any] ) {
        if let jsonResultString = dict[StatusResponse.KEY_RESULT] {
            let resultDict = jsonResultString as! [String : Any]
            self.result.resultText = jsonUtils.getString(
                dict: resultDict, key: StatusResponse.KEY_RESULT_TEXT )!
            self.result.resultType = jsonUtils.getString(
                dict:resultDict, key: StatusResponse.KEY_RESULT_TYPE)!
            self.result.smileJobID = jsonUtils.getString(
                dict:resultDict, key: StatusResponse.KEY_SMILE_JOB_ID )!
            self.result.jSONVersion = jsonUtils.getString(
                dict:resultDict, key: StatusResponse.KEY_JSON_VERSION )!
            self.result.isFinalResult = jsonUtils.getString(
                dict:resultDict, key: StatusResponse.KEY_IS_FINAL_RESULT )!
            self.result.confidenceValue = jsonUtils.getString(
                dict:resultDict, key: StatusResponse.KEY_CONFIDENCE_VALUE )!
            self.result.isMachineResult = jsonUtils.getString(
                dict:resultDict, key: StatusResponse.KEY_MACHINE_RESULT )!
        }
    }
    
    
    func setPartnerParamsValues( dict : [String : Any] ) {
        if let jsonParterParamsString = dict[StatusResponse.KEY_PARTNER_PARAMS] {
            let partnerParamsDict = jsonParterParamsString as! [String : Any]
            result.partnerParams.userId = jsonUtils.getString(dict: partnerParamsDict, key: PartnerParams.USER_ID )!
            result.partnerParams.jobId = jsonUtils.getString(dict: partnerParamsDict, key: PartnerParams.JOB_ID )!
            result.partnerParams.jobType = jsonUtils.getInt(dict: partnerParamsDict, key: PartnerParams.JOB_TYPE )!
        }
    }
    
    
    
    
}
