//
//  LamdaRequestJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/29/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class LamdaRequestJson {
    static let KEY_JSON_SMILE_CLIENT_ID    : String    = "smile_client_id"
    static let KEY_CAMERA_NAME         : String    = "camera_name"
    static let KEY_SEC                 : String    = "sec_key"
    static let KEY_RETRY               : String    = "retry"
    static let KEY_PARTNER_PARAMS      : String    = "partner_params"
    static let KEY_TIMESTAMP           : String    = "timestamp"
    static let KEY_MODEL_PARAMETERS    : String    = "model_parameters"
    static let KEY_FILE_NAME           : String    = "file_name"
    static let KEY_CALLBACK_URL        : String    = "callback_url"
    static let KEY_IMEI                : String    = "imei"
    static let KEY_PHONE_NUM           : String    = "phoneNum"
    static let KEY_PHONE_MAKE          : String    = "phoneMake"
    static let KEY_PHONE_MODEL         : String    = "phoneModel"
    static let KEY_PHONE_OS_VERSION    : String    = "phoneOSVersion"
    
    var phoneNumber         : String?
    var referenceId         : String?
    var deviceId            : String?
    var authResponse        : AuthSmileResponse?
    var partnerParams       : PartnerParams?
    var retry               : Bool?
    var smileClientId       : String?
    
    let jsonUtils           = JsonUtils()

    init(   phoneNumber : String,
            referenceId : String,
            deviceId    : String,
            authResponse: AuthSmileResponse,
            partnerParams: PartnerParams,
            retry : Bool,
            smileClientId : String ) {
        self.phoneNumber = phoneNumber;
        self.referenceId = referenceId;
        self.deviceId = deviceId;
        self.authResponse = authResponse;
        self.partnerParams = partnerParams;
        self.retry = retry;
        self.smileClientId = smileClientId;

    }
    
    
    func toJsonString() -> String {
        // Build a dictionary,
        // then convert it to a formatted json string
        var dict = [String: Any]()
  
        // get the partner params out of the auth response
        let rawJsonString = authResponse?.rawJsonString
        
        // Geth the auth response dictionary from the rawJsonString
        let authResponseDict = jsonUtils.jsonFormattedStringToDict( rawJsonString! )
        dict[LamdaRequestJson.KEY_SEC] = authResponseDict?[AuthSmileResponse.KEY_SEC]
        
        dict[LamdaRequestJson.KEY_RETRY] = String(retry!)
      
        // Get the partner params dictionary out of the authResponseDict
        var authResponsePartnerParamsDict = [String: String]()
        authResponsePartnerParamsDict = authResponseDict![AuthSmileResponse.KEY_PARTNER_PARAMS]  as! [String : String]
        // put the partner params dictionary into the lambdaRequest dictionary
        dict[LamdaRequestJson.KEY_PARTNER_PARAMS] = authResponsePartnerParamsDict
        dict[LamdaRequestJson.KEY_TIMESTAMP] = authResponseDict?[AuthSmileResponse.KEY_TIMESTAMP]
        
        var phoneModelDict = [String: String]()
        phoneModelDict[LamdaRequestJson.KEY_CAMERA_NAME] = UIDevice.current.model
        
        dict[LamdaRequestJson.KEY_MODEL_PARAMETERS] = phoneModelDict
        dict[LamdaRequestJson.KEY_FILE_NAME] = referenceId! + ".zip"
        dict[LamdaRequestJson.KEY_JSON_SMILE_CLIENT_ID] = smileClientId
        dict[LamdaRequestJson.KEY_CALLBACK_URL] = authResponseDict?[AuthSmileResponse.KEY_CALLBACK_URL]
        dict[LamdaRequestJson.KEY_IMEI] = deviceId
        if( phoneNumber != nil ){
            dict[LamdaRequestJson.KEY_PHONE_NUM] = phoneNumber
        }
        dict[LamdaRequestJson.KEY_PHONE_MAKE] = "Apple"
        // This is the same info as the KEY_CAMERA_NAME, but we
        // are porting the Android code, so need to keep the format
        // the same for now.
        dict[LamdaRequestJson.KEY_PHONE_MODEL] = UIDevice.current.model
        dict[LamdaRequestJson.KEY_PHONE_OS_VERSION] = UIDevice.current.systemVersion
        
        return jsonUtils.dictToJsonFormattedString( dict : dict )
    }
    


}
