//
//  LensCharacteristics.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import AVFoundation

 
class LensCharacteristics {
    
    static let KEY_FLASH_MODE       : String = "flashMode"
    static let KEY_FOCAL_LENGTH     : String = "focalLength"
    static let KEY_FPS_RANGE        : String = "fpsRange"
    static let KEY_HORIZONTAL_VIEW_ANGLE    : String =
        "horizontalViewAngle"
    static let KEY_JPEG_QUALITY             : String =
        "jpegQuality"
    static let KEY_JPEG_THUMBNAIL_QUALITY   : String =
        "jpegThumbnailQuality"
    static let KEY_MAX_FPS                  : String =
        "maxFPS"
    static let KEY_MAX_PREVIEW_HEIGHT       : String =
        "maxPreviewHeight"
    static let KEY_MAX_PREVIEW_WIDTH        : String =
        "maxPreviewWidth"
    static let KEY_MIN_FPS                  : String =
        "minFPS"
    static let KEY_VERTICAL_VIEW_ANGLE      : String =
        "verticalViewAngle"
     static let KEY_MAX_ZOOM                 : String =
        "maxZoom"
    static let KEY_WHITE_BALANCE            : String =
        "whiteBalance"
    

    /* default flash mode is off.
    See https://developer.apple.com/documentation/avfoundation/avcapturephotosettings/1648760-flashmode
     */
    var flashMode               : String = "off"
    // No api for these values
    var horizontalViewAngle     : Float     = 0.0
    var verticalViewAngle       : Float     = 0.0
    
    
    var jpegQuality             : Int       = 100
    var jpegThumbnailQuality    : Int       = 100
    
    // No api to get focalLength
    var focalLength             : Float = 0.0
    var maxZoom                 : Int       = 0
    
    var whiteBalance            : String    = "auto"
    
    var fpsRange                = FPSRange(min: 0, max:0)
    
    /*
    init (
        focalLength         : Float,
        flashMode           : String,
        horizontalViewAngle : Float,
        verticalViewAngle   : Float,
        jpegQuality         : Int,
        jpegThumbnailQuality: Int,
        maxZoom             : Int,
        fpsRange            : [Int],
        minFPS              : Int,
        maxFPS              : Int,
        maxPreviewWidth     : Int,
        maxPreviewHeight    : Int,
        whiteBalance        : String
        ){
        self.focalLength = focalLength
        self.flashMode = flashMode
        self.horizontalViewAngle = horizontalViewAngle
        self.verticalViewAngle = verticalViewAngle
        self.jpegQuality = jpegQuality
        self.jpegThumbnailQuality = jpegThumbnailQuality
        self.maxZoom = maxZoom
        self.fpsRange = fpsRange
        self.minFPS = minFPS
        self.maxFPS = maxFPS
        self.maxPreviewWidth = maxPreviewWidth
        self.maxPreviewHeight = maxPreviewHeight
        self.whiteBalance = whiteBalance
        
    }
     */
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
        
        jsonUtils.putString( dict: &dict, key: LensCharacteristics.KEY_FLASH_MODE,
            val: flashMode )
        
        jsonUtils.putFloat( dict: &dict, key: LensCharacteristics.KEY_FOCAL_LENGTH,
                             val: focalLength )
        
        // Create one fps range object.  Each fps range object
        // is an array.  [0] holds the min, [1] holds the max.
        let fpsRange = FPSRange( min:
            SmileIDSingleton.sharedInstance.minFPS,
            max:SmileIDSingleton.sharedInstance.maxFPS )
        var fpsRangeArray = [Any]()
        fpsRangeArray[0] = fpsRange.min
        fpsRangeArray[1] = fpsRange.max
        
        // Now create an array of fpsRanges.
        // In this case there is only one.
        var jsFpsRangeArray = [Any]()
        jsFpsRangeArray[0] = fpsRangeArray
        
        // Now put jsFpsRangeArray in the dictionary
        jsonUtils.putArray(dict: &dict, key: LensCharacteristics.KEY_FPS_RANGE, val:fpsRangeArray)
        
       
        jsonUtils.putFloat( dict: &dict, key: LensCharacteristics.KEY_HORIZONTAL_VIEW_ANGLE,
            val: horizontalViewAngle )
        
        jsonUtils.putFloat( dict: &dict, key: LensCharacteristics.KEY_VERTICAL_VIEW_ANGLE,
                            val: verticalViewAngle )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_JPEG_QUALITY,
                            val: jpegQuality )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_JPEG_THUMBNAIL_QUALITY,
                          val: jpegThumbnailQuality )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MAX_FPS,
            val: SmileIDSingleton.sharedInstance.maxFPS )
    
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MIN_FPS,
            val: SmileIDSingleton.sharedInstance.minFPS )

        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MAX_PREVIEW_WIDTH,
            val: SmileIDSingleton.sharedInstance.devicePortraitHorizontalResolution )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MAX_PREVIEW_HEIGHT,
                          val: SmileIDSingleton.sharedInstance.devicePortraitVerticalResolution )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MAX_ZOOM,
                          val:maxZoom )
        let sWhiteBalanceMode = whiteBalanceModeToString( whiteBalanceMode: SmileIDSingleton.sharedInstance.whiteBalanceMode )
        jsonUtils.putString( dict: &dict, key: LensCharacteristics.KEY_WHITE_BALANCE,
                             val: sWhiteBalanceMode )
        
        return jsonUtils.dictToJsonFormattedString( dict : dict )

    }
    
    
    func whiteBalanceModeToString(
        whiteBalanceMode : AVCaptureDevice.WhiteBalanceMode ) -> String {
        
        switch( whiteBalanceMode ){
            case AVCaptureDevice.WhiteBalanceMode.locked :
                return "locked"
            case AVCaptureDevice.WhiteBalanceMode.autoWhiteBalance :
                return "auto"
            case AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance:
                return "continuous"
        }
        
    }

}
