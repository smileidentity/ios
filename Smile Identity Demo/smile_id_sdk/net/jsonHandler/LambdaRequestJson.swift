//
//  LambdaRequestJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/29/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class LambdaRequestJson {
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
    var userInfoJson        : UserInfoJson?
    var geoInfos            : GeoInfos?
    
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
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> LambdaRequestJson? {
        let jsonUtils = JsonUtils()
        secKey = jsonUtils.getString(dict:dict,
                                     key: LambdaRequestJson.KEY_SEC )!
        
        let sRetry = jsonUtils.getString(dict:dict,
                                         key: LambdaRequestJson.KEY_RETRY )!
        if( sRetry == "true" ){
            retry = true
        }
        else{
            retry = false
        }
        
        let partnerParamsDict = jsonUtils.getDict( dict: dict, key: LambdaRequestJson.KEY_PARTNER_PARAMS )
        partnerParams = PartnerParams().fromJsonDict(dict: partnerParamsDict)
        
        timestamp = jsonUtils.getInt64( dict: dict, key: LambdaRequestJson.KEY_TIMESTAMP )
        
        let phoneModelDict = jsonUtils.getDict( dict: dict, key: LambdaRequestJson.KEY_MODEL_PARAMETERS )
        cameraModel = jsonUtils.getString( dict: phoneModelDict, key: LambdaRequestJson.KEY_CAMERA_NAME )
        
        filename = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_FILE_NAME )
        
        smileClientId = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_JSON_SMILE_CLIENT_ID )
        
        callbackURL = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_CALLBACK_URL )
        
        deviceId = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_IMEI )
        
        let tmpPhoneNumber = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_PHONE_NUM )
        if( tmpPhoneNumber != nil ){
            phoneNumber = tmpPhoneNumber
        }
        
        cameraMake = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_PHONE_MAKE )
        
        cameraModel = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_PHONE_MODEL )
        
        cameraModel = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_PHONE_MODEL )
        
        systemVersion = jsonUtils.getString( dict: dict, key: LambdaRequestJson.KEY_PHONE_OS_VERSION )
        
        
        let userInfoJsonDict = jsonUtils.getDict( dict: dict, key: LambdaRequestJson.KEY_USER_DATA )
        userInfoJson = UserInfoJson().fromJsonDict( dict: userInfoJsonDict )
        
        let geoInfosDict = jsonUtils.getDict( dict: dict, key: LambdaRequestJson.KEY_GEO_LOCATION )
        geoInfos = GeoInfos().fromJsonDict( dict: geoInfosDict )
        
        return self
        
   }
    
    func fromJsonString( jsonFormattedString : String ) -> LambdaRequestJson? {
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
        let secKey = jsonUtils.getString(dict:authResponseDict!,
                                         key: AuthSmileResponse.KEY_SEC )!
        // Put the secKey into the lambda request dictionary
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_SEC,
                             val: secKey )
        
        // Put the retry value as a string for compatibility purposes.
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_RETRY,
                             val:  String(retry!) )
        
        // Get the partner params dictionary out of the authResponseDict
        var authResponsePartnerParamsDict = [String: String]()
        authResponsePartnerParamsDict = authResponseDict![AuthSmileResponse.KEY_PARTNER_PARAMS]  as! [String : String]
        jsonUtils.putDict( dict: &dict, key: LambdaRequestJson.KEY_PARTNER_PARAMS,
                           val:  authResponsePartnerParamsDict )
        
        jsonUtils.putInt64( dict: &dict,key: LambdaRequestJson.KEY_TIMESTAMP,
                            val: authResponseDict?[AuthSmileResponse.KEY_TIMESTAMP] as! Int64 )
        
        var phoneModelDict = [String: Any]()
        jsonUtils.putString( dict: &phoneModelDict, key: LambdaRequestJson.KEY_CAMERA_NAME,
                             val: cameraModel! )
        jsonUtils.putDict( dict: &dict, key: LambdaRequestJson.KEY_MODEL_PARAMETERS,
                           val:  phoneModelDict )
        
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_FILE_NAME,
                             val: filename! )
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_JSON_SMILE_CLIENT_ID,
                             val: smileClientId! )
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_CALLBACK_URL,
                             val: authResponseDict?[AuthSmileResponse.KEY_CALLBACK_URL]! as! String )
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_IMEI,
                             val: deviceId! )
        
        
        if( phoneNumber != nil ){
            jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_PHONE_NUM,
                                 val: phoneNumber! )
        }
        
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_PHONE_MAKE,
                             val:cameraMake! )
        
        
        // This is the same info as the KEY_CAMERA_NAME, but we
        // are porting the Android code, so need to keep the format
        // the same for now.
        
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_PHONE_MODEL,
                             val:cameraModel!)
        
        jsonUtils.putString( dict: &dict, key: LambdaRequestJson.KEY_PHONE_OS_VERSION,
                             val:systemVersion!)
        
        jsonUtils.putDict( dict: &dict, key: LambdaRequestJson.KEY_USER_DATA,
                           val:(userInfoJson?.toJsonDict())! )
        
        jsonUtils.putDict( dict: &dict, key: LambdaRequestJson.KEY_GEO_LOCATION,
                           val:(geoInfos?.toJsonDict())! )

        return dict
    }
    
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
    

}
