//
//  SIDDeviceCameraInfos.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class SIDDeviceCameraInfos {
    
    static let KEY_AVAILABLE_IMAGE_FORMAT : String = "availableImageFormat"
    static let KEY_CAMERA_MODEL                 : String =
        "cameraModel"
    static let KEY_COLOR_DEPTH                  : String =
        "colorDepth"
    static let KEY_DEVICE_PORTRAIT_HORIZONTAL_RESOLUTION    : String = "devicePortraitHorizontalResolution"
    static let KEY_DEVICE_PORTRAIT_VERTICAL_RESOLUTION      : String = "devicePortraitVerticalResolution"
    static let KEY_MAX_FPS                      : String =
        "maxFPS"
    static let KEY_MAX_IMAGE_MEMORY             : String =
        "maxImageMemory"
    static let KEY_PREVIEW_SIZE_LIST            : String =
        "previewSizeList"
    static let KEY_SELFIE_CAMERA_EXISTS         : String =
        "selfieCameraExists"
    
    static let FPS_VALUE                    = 1000
    
    var availableImageFormat                : String = "jpg"
    var model                               : String = UIDevice.current.model
    var colorDepth                          : Int = 0
    var devicePortraitHorizontalResolution  : Int = SmileIDSingleton.sharedInstance.lensCharacteristicsFront.devicePortraitHorizontalResolution
    var devicePortraitVerticalResolution    : Int = SmileIDSingleton.sharedInstance.lensCharacteristicsFront.devicePortraitVerticalResolution
    var maxFPS                              : Int =
        SmileIDSingleton.sharedInstance.lensCharacteristicsFront.maxFPS
    var maxImageMemory                      : Int = 0
    var previewSize                         = PreviewSize()
    
    var lensCharacteristics                 = LensCharacteristics()
 
    // indicates if this object refers to the back camera or the front camera
    var isFront                             : Bool = false
    var selfieExists                        : Bool = SmileIDSingleton.sharedInstance.selfieCameraExists
    
    init(){}
    
    init(  lensCharacteristics  : LensCharacteristics,
           isFront              : Bool ){
        
        self.isFront = isFront
        self.lensCharacteristics = lensCharacteristics
        
        let siFileManager = SIFileManager()
        self.maxImageMemory = Int(truncatingIfNeeded: siFileManager.getFreeDiskspace()!)
        
        previewSize = PreviewSize( width:devicePortraitHorizontalResolution,
                     height:devicePortraitVerticalResolution)
   
    }
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> SIDDeviceCameraInfos? {
        let jsonUtils = JsonUtils()
        
        availableImageFormat = jsonUtils.getString(dict:dict,
            key: SIDDeviceCameraInfos.KEY_AVAILABLE_IMAGE_FORMAT,
            defaultVal : "jpg" )
            
        model = jsonUtils.getString(dict:dict,
            key: SIDDeviceCameraInfos.KEY_CAMERA_MODEL,
            defaultVal: "" )
        
        colorDepth = jsonUtils.getInt(dict:dict,
            key: SIDDeviceCameraInfos.KEY_COLOR_DEPTH,
            defaultVal : 0 )
        
        devicePortraitHorizontalResolution = jsonUtils.getInt(dict:dict,
            key: SIDDeviceCameraInfos.KEY_DEVICE_PORTRAIT_HORIZONTAL_RESOLUTION,
            defaultVal : 0 )
        
        devicePortraitVerticalResolution = jsonUtils.getInt(dict:dict,
            key: SIDDeviceCameraInfos.KEY_DEVICE_PORTRAIT_VERTICAL_RESOLUTION,
            defaultVal : 0 )
        
        maxFPS = jsonUtils.getInt(dict:dict,
            key: SIDDeviceCameraInfos.KEY_MAX_FPS,
            defaultVal : 0 )
        
        maxImageMemory = jsonUtils.getInt(dict:dict,
            key: SIDDeviceCameraInfos.KEY_MAX_IMAGE_MEMORY,
            defaultVal : 0 )
        
        /* An array of dictionaries */
        var previewSizeList = [Dictionary<String,Any>]()
        let defaultArr = [Any]()
        previewSizeList = jsonUtils.getArray(dict:dict,
            key: SIDDeviceCameraInfos.KEY_PREVIEW_SIZE_LIST,
            defaultVal : defaultArr ) as! [Dictionary<String, Any>]
        if( previewSizeList.count > 0 ){
        
        let previewDict = previewSizeList[0]
        previewSize.width = previewDict[PreviewSize.KEY_WIDTH] as! Int
        previewSize.height = previewDict[PreviewSize.KEY_HEIGHT] as! Int
        }
        else{
            previewSize.width = 0
            previewSize.height = 0
        }
        
        selfieExists = jsonUtils.getBool(dict:dict,
            key: SIDDeviceCameraInfos.KEY_SELFIE_CAMERA_EXISTS,
            defaultVal : false )
        
        return self
        
     }
    
    func fromJsonString( jsonFormattedString : String ) -> SIDDeviceCameraInfos? {
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
        // Build a dictionary,
        var dict = [String: Any]()
        
        let jsonUtils = JsonUtils()
        
        jsonUtils.putString( dict: &dict, key: SIDDeviceCameraInfos.KEY_AVAILABLE_IMAGE_FORMAT,
            val: availableImageFormat )
        
        jsonUtils.putString( dict: &dict, key: SIDDeviceCameraInfos.KEY_CAMERA_MODEL,
            val: model )
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_COLOR_DEPTH,
            val: colorDepth )
        
        /* Ported from Android code.  Note that the android code
         does not switch vertical and horizontal device resolution
         when creating the json for front or back camera.
         front camera orientation is portrait, for the selfie,
         and back camera is landscape for the id card.
         */
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_DEVICE_PORTRAIT_HORIZONTAL_RESOLUTION,
            val: devicePortraitHorizontalResolution )
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_DEVICE_PORTRAIT_VERTICAL_RESOLUTION,
            val: devicePortraitVerticalResolution )
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_MAX_FPS,
            val: maxFPS )
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_MAX_IMAGE_MEMORY,
            val:maxImageMemory)
        
        // An array of dictionaries.
        // https://stackoverflow.com/questions/37776334/parse-//json-without-key-in-swift
        var previewSizeList = [Dictionary<String,Any>]()
        previewSizeList.append(previewSize.toJsonDict())
        
        jsonUtils.putArray(dict: &dict, key:SIDDeviceCameraInfos.KEY_PREVIEW_SIZE_LIST,
            val: previewSizeList)
        
        jsonUtils.putBool(dict: &dict, key:SIDDeviceCameraInfos.KEY_SELFIE_CAMERA_EXISTS,
            val:selfieExists)
        
        return dict
        
        
    }
    
    func toJsonString() -> String {
        
        let jsonUtils = JsonUtils()

        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
}
