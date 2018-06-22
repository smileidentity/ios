//
//  MiscInfoJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class MiscInfo {
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
    var retry               : Bool?
    var partnerParams       : PartnerParams?
    var timestamp           : Int64?  // server returns int64 utc
    var cameraModel         : String?
    var filename            : String?
    var smileClientId       : String?
    var callbackURL         : String?
    var deviceId            : String?
    var phoneNumber         : String?
    var cameraMake          : String?
    var systemVersion       : String?

    /* not stored in info.json
    var referenceId         : String?
    var authResponse        : AuthSmileResponse?
    */
 
 
    /* userInfoJson and geoInfos are not built into the request,
     but they are added in when building the info.json file.
     Ported from Android code to maintain compatibility
     */
    var userInfoJson        : UserInfoJson?
    var geoInfos            : GeoInfos?

    let jsonUtils           = JsonUtils()

    init(){}

    init( lambdaRequest : LambdaRequest,
          userInfoJson : UserInfoJson,
          geoInfos : GeoInfos ) {
        self.secKey = lambdaRequest.secKey
        self.phoneNumber = lambdaRequest.phoneNumber;
        self.deviceId = lambdaRequest.deviceId;
        self.partnerParams = lambdaRequest.partnerParams;
        self.retry = lambdaRequest.retry;
        self.smileClientId = lambdaRequest.smileClientId;
        self.timestamp = lambdaRequest.timestamp
        self.filename = lambdaRequest.filename
        self.cameraModel = lambdaRequest.cameraModel
        self.systemVersion = lambdaRequest.systemVersion
        self.cameraMake = lambdaRequest.cameraMake
        self.callbackURL = lambdaRequest.callbackURL
        self.userInfoJson = userInfoJson
        self.geoInfos = geoInfos
        
    }

    func fromJsonDict( dict : Dictionary<String,Any> ) -> MiscInfo? {
        let jsonUtils = JsonUtils()
        secKey = jsonUtils.getString(dict:dict,
                                     key: MiscInfo.KEY_SEC,
                                     defaultVal: "" )
        let sRetry = jsonUtils.getString(dict:dict,
                                         key: MiscInfo.KEY_RETRY,
                                         defaultVal: "false" )
        if( sRetry == "true" ){
            retry = true
        }
        else{
            retry = false
        }
        let partnerParamsDict = jsonUtils.getDict( dict: dict, key: MiscInfo.KEY_PARTNER_PARAMS,
                                                   defaultVal : [String:Any]() )
        partnerParams = PartnerParams().fromJsonDict(dict: partnerParamsDict)
        timestamp = jsonUtils.getInt64( dict: dict, key: MiscInfo.KEY_TIMESTAMP,
                                        defaultVal: 0 )

        let phoneModelDict = jsonUtils.getDict( dict: dict, key: MiscInfo.KEY_MODEL_PARAMETERS,
                                                defaultVal: [String:Any]() )
        
        cameraModel = jsonUtils.getString( dict: phoneModelDict, key: MiscInfo.KEY_CAMERA_NAME,
                                           defaultVal: "" )
        
        filename = jsonUtils.getString( dict: dict,
                                        key: MiscInfo.KEY_FILE_NAME,
                                        defaultVal: "" )
        
        smileClientId = jsonUtils.getString( dict: dict,
                                             key: MiscInfo.KEY_JSON_SMILE_CLIENT_ID,
                                             defaultVal: "" )
        
        callbackURL = jsonUtils.getString( dict: dict,
                                           key: MiscInfo.KEY_CALLBACK_URL,
                                           defaultVal: "" )
        
        deviceId = jsonUtils.getString( dict: dict,
                                        key: MiscInfo.KEY_IMEI,
                                        defaultVal: "" )
        
        let tmpPhoneNumber = jsonUtils.getString( dict: dict,
                                                  key: MiscInfo.KEY_PHONE_NUM,
                                                  defaultVal: "" )
        if( !tmpPhoneNumber.isEmpty ){
            phoneNumber = tmpPhoneNumber
        }
        
        
        cameraMake = jsonUtils.getString( dict: dict,
                                          key: MiscInfo.KEY_PHONE_MAKE,
                                          defaultVal: "" )
        
        cameraModel = jsonUtils.getString( dict: dict,
                                           key: MiscInfo.KEY_PHONE_MODEL,
                                           defaultVal: "" )
        
        cameraModel = jsonUtils.getString( dict: dict,
                                           key: MiscInfo.KEY_PHONE_MODEL,
                                           defaultVal: "" )
        
        systemVersion = jsonUtils.getString( dict: dict,
                                             key: MiscInfo.KEY_PHONE_OS_VERSION,
                                             defaultVal: "" )
        
        
        let userInfoJsonDict = jsonUtils.getDict( dict: dict,
                                                  key: MiscInfo.KEY_USER_DATA,
                                                  defaultVal: [String:Any]() )
        userInfoJson = UserInfoJson().fromJsonDict( dict: userInfoJsonDict )
        
        let geoInfosDict = jsonUtils.getDict( dict: dict,
                                              key: MiscInfo.KEY_GEO_LOCATION,
                                              defaultVal : [String:Any]())
        geoInfos = GeoInfos().fromJsonDict( dict: geoInfosDict )
        
        return self
        
    }

    func fromJsonString( jsonFormattedString : String ) -> MiscInfo? {
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
        
        // Put the secKey into the lambda request dictionary
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_SEC,
                             val: secKey! )
        
        // Put the retry value as a string for compatibility purposes.
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_RETRY,
                             val:  String(retry!) )
        
        jsonUtils.putDict( dict: &dict, key: MiscInfo.KEY_PARTNER_PARAMS,
                           val: (partnerParams?.toJsonDict())! )
        
        jsonUtils.putInt64( dict: &dict,key: MiscInfo.KEY_TIMESTAMP,
                            val: timestamp! )
        
        var phoneModelDict = [String: Any]()
        jsonUtils.putString( dict: &phoneModelDict, key: MiscInfo.KEY_CAMERA_NAME,
                             val: cameraModel! )
        jsonUtils.putDict( dict: &dict, key: MiscInfo.KEY_MODEL_PARAMETERS,
                           val:  phoneModelDict )
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_FILE_NAME,
                             val: filename! )
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_JSON_SMILE_CLIENT_ID,
                             val: smileClientId! )
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_CALLBACK_URL,
                             val: callbackURL!)
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_IMEI,
                             val: deviceId! )
        
        
        if( phoneNumber != nil ){
            jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_PHONE_NUM,
                                 val: phoneNumber! )
        }
        
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_PHONE_MAKE,
                             val:cameraMake! )
        
        
        // This is the same info as the KEY_CAMERA_NAME, but we
        // are porting the Android code, so need to keep the format
        // the same for now.
        
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_PHONE_MODEL,
                             val:cameraModel!)
        
        jsonUtils.putString( dict: &dict, key: MiscInfo.KEY_PHONE_OS_VERSION,
                             val:systemVersion!)
        
        jsonUtils.putDict( dict: &dict, key: MiscInfo.KEY_USER_DATA,
                           val:(userInfoJson?.toJsonDict())! )
        
        jsonUtils.putDict( dict: &dict, key: MiscInfo.KEY_GEO_LOCATION,
                           val:(geoInfos?.toJsonDict())! )
        
        return dict
    }



    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
}

