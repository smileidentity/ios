//
//  MetaData.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class PackageInfo {
    
    static let KEY_SID_DEVICE_CAMERA_INFOS_BACK     :
        String = "SIDDeviceCameraInfosBackCam"
   
    static let KEY_SID_DEVICE_CAMERA_INFOS_FRONT    :
        String = "SIDDeviceCameraInfosFrontCam"
    
    static let KEY_API_VERSION                      :
        String = "apiVersion"

    static let KEY_CAPTURE_CONFIG                   :
        String = "captureConfig"
    
    static let KEY_FRAME_INFO                       :
        String = "frameInfo"

    static let KEY_FRAME_INFO_ID_CARD               :
        String = "frameInfoIDCard"

    static let KEY_FRAME_INFO_PREVIEW_FULL          :
        String = "frameInfoPreviewFull"

    static let KEY_IS_MAX_FRAME_TIMEOUT             :
        String = "isMaxFrameTimeout"

    static let KEY_REFERENCE_ID                     :
        String = "referenceId"
 
    static let KEY_SECURITY_CAPS                    :
        String = "securityCaps"
    
    
    var referenceId                 : String?
    var apiVersion                  : APIVersion?
    var captureConfig               : CaptureConfig?
    var sidDeviceCameraInfosFront   : SIDDeviceCameraInfos?
    var sidDeviceCameraInfosBack    : SIDDeviceCameraInfos?
    
    var securityCaps                : SecurityCaps?
    var fullFrameInfoList           : [FullFrameInfo]?
    var frameInfoPreviewFull        : FullFrameInfo?
    var frameInfoIDCard             : FullFrameInfo?
    var isMaxFrameTimeout           : Bool?
    
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> PackageInfo? {
        let jsonUtils = JsonUtils()
        
        let sidDeviceCameraInfosBackDict = jsonUtils.getDict(dict:dict,
            key: PackageInfo.KEY_SID_DEVICE_CAMERA_INFOS_BACK )
        sidDeviceCameraInfosBack = SIDDeviceCameraInfos().fromJsonDict(dict: sidDeviceCameraInfosBackDict)
        
        let sidDeviceCameraInfosFrontDict = jsonUtils.getDict(dict:dict,
            key: PackageInfo.KEY_SID_DEVICE_CAMERA_INFOS_FRONT )
        sidDeviceCameraInfosFront = SIDDeviceCameraInfos().fromJsonDict(dict: sidDeviceCameraInfosFrontDict)
        
        let apiVersionDict = jsonUtils.getDict(dict:dict,
            key: PackageInfo.KEY_API_VERSION )
        apiVersion = APIVersion().fromJsonDict(dict: apiVersionDict)

        let captureConfigDict = jsonUtils.getDict(dict:dict,
            key: PackageInfo.KEY_CAPTURE_CONFIG )
        captureConfig = CaptureConfig().fromJsonDict(dict: captureConfigDict)

        /* An array of dictionaries */
        var frameInfoDictArray = [Dictionary<String,Any>]()
        frameInfoDictArray =  jsonUtils.getArray(dict:dict,
            key: PackageInfo.KEY_FRAME_INFO ) as! [Dictionary<String, Any>]
        
        fullFrameInfoList = [FullFrameInfo]()
        for frameInfoDict in frameInfoDictArray {
            let frameData = FullFrameInfo().fromJsonDict( dict: frameInfoDict )
            fullFrameInfoList?.append(frameData!)
        }
    
        
        let frameInfoIdCardDict = jsonUtils.getDict(dict:dict,
                key: PackageInfo.KEY_FRAME_INFO_ID_CARD )
        frameInfoIDCard = FullFrameInfo().fromJsonDict(dict: frameInfoIdCardDict)

        let frameInfoPreviewFullDict = jsonUtils.getDict(dict:dict,
                key: PackageInfo.KEY_FRAME_INFO_PREVIEW_FULL )
        frameInfoPreviewFull = FullFrameInfo().fromJsonDict(dict: frameInfoPreviewFullDict)
        
        isMaxFrameTimeout = jsonUtils.getBool(dict:dict,
            key: PackageInfo.KEY_IS_MAX_FRAME_TIMEOUT )
 
        referenceId = jsonUtils.getString(dict:dict,
            key: PackageInfo.KEY_REFERENCE_ID )
        
        let securityCapsDict = jsonUtils.getDict(dict:dict,
            key: PackageInfo.KEY_SECURITY_CAPS )
        securityCaps = SecurityCaps().fromJsonDict(dict: securityCapsDict)

        
        return self
       
    }
    
    func fromJsonString( jsonFormattedString : String ) -> PackageInfo? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            let jsonUtils = JsonUtils()
            
            let dict = jsonUtils.jsonFormattedStringToDict(
                jsonFormattedString )
            
            return fromJsonDict(dict: dict!)
        }
        
        return self
    }
    func toJsonDict() -> Dictionary<String,Any> {
        // Build a dictionary,
        var dict = [String: Any]()
        
        let jsonUtils = JsonUtils()
       
        jsonUtils.putDict( dict: &dict, key: PackageInfo.KEY_SID_DEVICE_CAMERA_INFOS_BACK,
            val: (sidDeviceCameraInfosBack?.toJsonDict())! )
        
        jsonUtils.putDict( dict: &dict, key: PackageInfo.KEY_SID_DEVICE_CAMERA_INFOS_FRONT,
            val: (sidDeviceCameraInfosFront?.toJsonDict())! )
        
        jsonUtils.putDict( dict: &dict, key: PackageInfo.KEY_API_VERSION,
                           val: (apiVersion?.toJsonDict())! )
        
        jsonUtils.putDict( dict: &dict, key: PackageInfo.KEY_CAPTURE_CONFIG,
                           val: (captureConfig?.toJsonDict())! )
        
        
        /* frame info is a json array, where each item is a
            dictionary containing a frame */
        // An array of dictionaries.
        // https://stackoverflow.com/questions/37776334/parse-//json-without-key-in-swift
        var frameInfoDictArray = [Dictionary<String,Any>]()
        for frameData in fullFrameInfoList! {
            frameInfoDictArray.append(frameData.toJsonDict() )
        }
        jsonUtils.putArray(dict: &dict, key:PackageInfo.KEY_FRAME_INFO,
            val: frameInfoDictArray)
        
        jsonUtils.putDict( dict: &dict, key: PackageInfo.KEY_FRAME_INFO_ID_CARD,
            val: (frameInfoIDCard?.toJsonDict())! )
        
        jsonUtils.putDict( dict: &dict, key: PackageInfo.KEY_FRAME_INFO_PREVIEW_FULL,
            val: (frameInfoPreviewFull?.toJsonDict())! )
        
        jsonUtils.putBool( dict: &dict, key: PackageInfo.KEY_IS_MAX_FRAME_TIMEOUT,
            val: isMaxFrameTimeout! )
        
        jsonUtils.putString( dict: &dict, key: PackageInfo.KEY_REFERENCE_ID,
            val: referenceId! )
        
        jsonUtils.putDict( dict: &dict, key: PackageInfo.KEY_SECURITY_CAPS,
            val: (securityCaps?.toJsonDict())! )
        
        return dict
        
    }
    
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
    
    
  
}
