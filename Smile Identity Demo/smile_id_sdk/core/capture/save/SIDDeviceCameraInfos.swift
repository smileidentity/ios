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
    var colorDepth                          : Int = 0
    
    var lensCharacteristics                 = LensCharacteristics()
 
    var isFront                             : Bool = false
    
    init(  lensCharacteristics  : LensCharacteristics,
           isFront              : Bool ){
        
        self.isFront = isFront
        self.lensCharacteristics = lensCharacteristics
    }
    
    
    func toJsonDict() -> Dictionary<String,Any> {
        // Build a dictionary,
        var dict = [String: Any]()
        
        let jsonUtils = JsonUtils()
        
        jsonUtils.putString( dict: &dict, key: SIDDeviceCameraInfos.KEY_AVAILABLE_IMAGE_FORMAT,
                             val: availableImageFormat )
        
        jsonUtils.putString( dict: &dict, key: SIDDeviceCameraInfos.KEY_CAMERA_MODEL,
                             val: UIDevice.current.model )
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_COLOR_DEPTH,
                          val: colorDepth )
        
        /* Ported from Android code.  Note that the android code
         does not switch vertical and horizontal device resolution
         when creating the json for front or back camera.
         front camera orientation is portrait, for the selfie,
         and back camera is landscape for the id card.
         */
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_DEVICE_PORTRAIT_HORIZONTAL_RESOLUTION,
                          val: SmileIDSingleton.sharedInstance.devicePortraitHorizontalResolution )
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_DEVICE_PORTRAIT_VERTICAL_RESOLUTION,
                          val: SmileIDSingleton.sharedInstance.devicePortraitVerticalResolution )
        
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_MAX_FPS,
                          val: SmileIDSingleton.sharedInstance.maxFPS )
        
        let siFileManager = SIFileFileManager()
        jsonUtils.putInt( dict: &dict, key: SIDDeviceCameraInfos.KEY_MAX_IMAGE_MEMORY,
                          val:Int(truncatingIfNeeded: siFileManager.getFreeDiskspace()!))
        
        
        let cameraSize = CameraSize( width: SmileIDSingleton.sharedInstance.devicePortraitHorizontalResolution, height:SmileIDSingleton.sharedInstance.devicePortraitVerticalResolution)
        
        // An array of dictionaries.
        // https://stackoverflow.com/questions/37776334/parse-//json-without-key-in-swift
        var previewSizeList = [Dictionary<String,Int>]()
        previewSizeList.append(cameraSize.toJsonDict())
        jsonUtils.putArray(dict: &dict, key:SIDDeviceCameraInfos.KEY_PREVIEW_SIZE_LIST,
                           val: previewSizeList)
        
        
        jsonUtils.putBool(dict: &dict, key:SIDDeviceCameraInfos.KEY_SELFIE_CAMERA_EXISTS,
                          val:SmileIDSingleton.sharedInstance.selfieCameraExists)
        
        return dict
        
        
    }
    
    func toJsonString() -> String {
        
        let jsonUtils = JsonUtils()

        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
}
