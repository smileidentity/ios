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
    
    var fullFilePath                        : String?
    
    var lensCharacteristics                 : LensCharacteristics?
    var availableImageFormat                : String?

    var colorDepth                          : Int = 0
    var maxFPS                              : Float =  0.0
    var maxImageMemory                      : Int64 = 0
    var isFront                             : Bool = false
    var previewSizeList                     = [CameraSize]()
    
    
    init(  framePath            : String,
           lensCharacteristics  : LensCharacteristics,
           isFront              : Bool,
           previewSizeList      : [CameraSize] ){
        
        availableImageFormat = ".jpg"
        self.isFront = isFront
        
        // colorDepth is implemented to maintain compatibility
        // with the Android code JSON format
        colorDepth = 0
        
 
    }
        
        
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
        
        jsonUtils.putString( dict: &dict, key: SIDDeviceCameraInfos.KEY_AVAILABLE_IMAGE_FORMAT,
                             val: availableImageFormat! )
        
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
        previewSizeList.append(cameraSize)
        
        jsonUtils.putArray(dict: &dict, key:SIDDeviceCameraInfos.KEY_PREVIEW_SIZE_LIST,
            val: previewSizeList)
        
        jsonUtils.putBool(dict: &dict, key:SIDDeviceCameraInfos.KEY_SELFIE_CAMERA_EXISTS,
        val:SmileIDSingleton.sharedInstance.selfieCameraExists)
 
        return jsonUtils.dictToJsonFormattedString( dict : dict )

    }
    
    
    
    
}
