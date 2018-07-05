//
//  LambdaRequestJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/29/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class LambdaRequest {
    static let KEY_JSON_SMILE_CLIENT_ID     : String    = "smile_client_id"
    static let KEY_CAMERA_NAME              : String    = "camera_name"
    static let KEY_SEC                      : String    = "sec_key"
    static let KEY_RETRY                    : String    = "retry"
    static let KEY_PARTNER_PARAMS           : String    = "partner_params"
    static let KEY_TIMESTAMP                : String    = "timestamp"
    static let KEY_MODEL_PARAMETERS         : String    = "model_parameters"
    static let KEY_FILE_NAME                : String    = "file_name"
    static let KEY_CALLBACK_URL             : String    = "callback_url"
    static let KEY_IMEI                     : String    = "imei"
    static let KEY_PHONE_NUM                : String    = "phoneNum"
    static let KEY_PHONE_MAKE               : String    = "phoneMake"
    static let KEY_PHONE_MODEL              : String    = "phoneModel"
    static let KEY_PHONE_OS_VERSION         : String    = "phoneOSVersion"
    static let KEY_USER_DATA                : String    = "userData"
    static let KEY_GEO_LOCATION             : String    = "GeoLocation"
    
    
    
    /* These values are sent to the server */
    var secKey              : String?
    var phoneNumber         : String?
    var referenceId         : String?
    var deviceId            : String?
    var authResponse        : AuthSmileResponse?
    var partnerParams       : PartnerParams?
    var retry               : Bool?
    var smileClientId       : String?
    
    var timestamp           : Int64?  // server returns int64 utc
    var filename            : String?
    var cameraModel         : String?
    var systemVersion       : String?
    var cameraMake          : String?
    var callbackURL         : String?
    
    /* userInfoJson and geoInfos are not built into the request,
        but they are added in when building the info.json file.
        Ported from Android code to maintain compatibility
    */
    var geoInfos            : GeoInfos?
    
    var userInfoJson        : UserInfoJson?
    
    let jsonUtils           = JsonUtils()
    
    init(){}

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
        self.filename = referenceId + ".zip"
        self.cameraModel = UIDevice.current.model
        self.systemVersion = UIDevice.current.systemVersion
        self.cameraMake = "Apple"
 
    }
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> LambdaRequest? {
        let jsonUtils = JsonUtils()
        secKey = jsonUtils.getString(dict:dict,
            key: LambdaRequest.KEY_SEC,
            defaultVal: "" )
        
        let sRetry = jsonUtils.getString(dict:dict,
            key: LambdaRequest.KEY_RETRY,
            defaultVal: "false" )
        
        if( sRetry == "true" ){
            retry = true
        }
        else{
            retry = false
        }
        
        let partnerParamsDict = jsonUtils.getDict( dict: dict, key: LambdaRequest.KEY_PARTNER_PARAMS,
            defaultVal : [String:Any]() )
        partnerParams = PartnerParams().fromJsonDict(dict: partnerParamsDict)
        
        timestamp = jsonUtils.getInt64( dict: dict, key: LambdaRequest.KEY_TIMESTAMP,
            defaultVal: 0 )
        
        let phoneModelDict = jsonUtils.getDict( dict: dict, key: LambdaRequest.KEY_MODEL_PARAMETERS,
            defaultVal: [String:Any]() )
        
        cameraModel = jsonUtils.getString( dict: phoneModelDict, key: LambdaRequest.KEY_CAMERA_NAME,
            defaultVal: "" )
        
        filename = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_FILE_NAME,
            defaultVal: "" )
        
        smileClientId = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_JSON_SMILE_CLIENT_ID,
            defaultVal: "" )
        
        callbackURL = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_CALLBACK_URL,
            defaultVal: "" )
        
        deviceId = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_IMEI,
            defaultVal: "" )
        
        let tmpPhoneNumber = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_PHONE_NUM,
            defaultVal: "" )
        
        if( !tmpPhoneNumber.isEmpty ){
            phoneNumber = tmpPhoneNumber
        }
        
        cameraMake = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_PHONE_MAKE,
            defaultVal: "" )
        
        cameraModel = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_PHONE_MODEL,
            defaultVal: "" )
        
        cameraModel = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_PHONE_MODEL,
            defaultVal: "" )
        
        systemVersion = jsonUtils.getString( dict: dict,
            key: LambdaRequest.KEY_PHONE_OS_VERSION,
            defaultVal: "" )
        
        
        let userInfoJsonDict = jsonUtils.getDict( dict: dict,
            key: LambdaRequest.KEY_USER_DATA,
            defaultVal: [String:Any]() )
        userInfoJson = UserInfoJson().fromJsonDict( dict: userInfoJsonDict )
        
        /* GeoInfos are not in the lambda request when it is sent to the server.
            They are only put into the metadata file */
        
        return self
        
   }
    
    func fromJsonString( jsonFormattedString : String ) -> LambdaRequest? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            let jsonUtils = JsonUtils()
            
            let dict = jsonUtils.jsonFormattedStringToDict(
                jsonFormattedString )
            return fromJsonDict( dict: dict! )
            
        }
        
       
    }
    
    

    func toJsonDict() -> Dictionary<String,Any> {
        
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
        
        // get the partner params out of the auth response
        let rawJsonString = authResponse?.rawJsonString
        
        // Get the auth response dictionary from the rawJsonString
        let authResponseDict = jsonUtils.jsonFormattedStringToDict( rawJsonString! )
        // Get the sec_key out of the authResponseDict
        secKey = jsonUtils.getString(dict:authResponseDict!,
                                         key: AuthSmileResponse.KEY_SEC,
                                         defaultVal: "" )
        // Put the secKey into the lambda request dictionary
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_SEC,
                             val: secKey! )
        
        // Put the retry value as a string for compatibility purposes.
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_RETRY,
                             val:  String(retry!) )
        
        // Get the partner params dictionary out of the authResponseDict
        /*
        let authResponsePartnerParamsDict = jsonUtils.getDict(dict: authResponseDict!,
                                                key: AuthSmileResponse.KEY_PARTNER_PARAMS,
                                                defaultVal:  [String:Any]() )
        let partnerParams = PartnerParams().fromJsonDict(dict: authResponsePartnerParamsDict)
 */
        
        let authResponsePartnerParamsDict = authResponseDict![AuthSmileResponse.KEY_PARTNER_PARAMS] as! Dictionary<String,Any>
        partnerParams = partnerParams?.fromJsonDict(dict: authResponsePartnerParamsDict )
        jsonUtils.putDict( dict: &dict, key: LambdaRequest.KEY_PARTNER_PARAMS,
                           val:  authResponsePartnerParamsDict )
        
        timestamp = jsonUtils.getInt64(dict: authResponseDict!, key: AuthSmileResponse.KEY_TIMESTAMP, defaultVal: 0)
        jsonUtils.putInt64( dict: &dict,key: LambdaRequest.KEY_TIMESTAMP,
                            val: timestamp! )
        
        var phoneModelDict = [String: Any]()
        jsonUtils.putString( dict: &phoneModelDict, key: LambdaRequest.KEY_CAMERA_NAME,
                             val: cameraModel! )
        jsonUtils.putDict( dict: &dict, key: LambdaRequest.KEY_MODEL_PARAMETERS,
                           val:  phoneModelDict )
        
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_FILE_NAME,
                             val: filename! )
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_JSON_SMILE_CLIENT_ID,
                             val: smileClientId! )
        
        callbackURL = jsonUtils.getString(dict:authResponseDict!, key: AuthSmileResponse.KEY_CALLBACK_URL,  defaultVal: "" )
        
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_CALLBACK_URL,
                             val: callbackURL! )
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_IMEI,
                             val: deviceId! )
        
        
        if( phoneNumber != nil ){
            jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_PHONE_NUM,
                                 val: phoneNumber! )
        }
        
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_PHONE_MAKE,
                             val:cameraMake! )
        
        
        // This is the same info as the KEY_CAMERA_NAME, but we
        // are porting the Android code, so need to keep the format
        // the same for now.
        
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_PHONE_MODEL,
                             val:cameraModel!)
        
        jsonUtils.putString( dict: &dict, key: LambdaRequest.KEY_PHONE_OS_VERSION,
                             val:systemVersion!)
        
        if( userInfoJson != nil ){
            jsonUtils.putDict( dict: &dict, key: LambdaRequest.KEY_USER_DATA,
                           val:(userInfoJson?.toJsonDict())! )
        }
        else{
            jsonUtils.putDict( dict: &dict, key: LambdaRequest.KEY_USER_DATA,
                               val: [String: Any]())
        }
        
        if( geoInfos != nil ){
            jsonUtils.putDict( dict: &dict, key: LambdaRequest.KEY_GEO_LOCATION,
                           val:(geoInfos?.toJsonDict())! )
        }
 
        /* GeoInfos are not in the lambda request when it is sent to the server.
         They are only put into the metadata file */
        
        return dict
    }
    
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
    

}
