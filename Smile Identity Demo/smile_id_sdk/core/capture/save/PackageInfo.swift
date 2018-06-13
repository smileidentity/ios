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
    
    func fromDict() -> PackageInfo {
        
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
        var frameInfoDictList = [Dictionary<String,Any>]()
        for frameData in fullFrameInfoList! {
            frameInfoDictList.append(frameData.toJsonDict() )
        }
        
        jsonUtils.putArray(dict: &dict, key:PackageInfo.KEY_FRAME_INFO,
            val: frameInfoDictList)
        
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
    
    
    
  
}
