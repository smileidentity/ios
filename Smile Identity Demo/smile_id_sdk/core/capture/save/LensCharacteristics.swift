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
    
   
    var fpsRange                = FPSRange(min: 0, max:0)
    
    var maxFPS                  : Int = SmileIDSingleton.sharedInstance.maxFPS
    var minFPS                  : Int = SmileIDSingleton.sharedInstance.minFPS
    var devicePortraitHorizontalResolution :Int =  SmileIDSingleton.sharedInstance.devicePortraitHorizontalResolution
    var devicePortraitVerticalResolution : Int = SmileIDSingleton.sharedInstance.devicePortraitVerticalResolution
    var whiteBalanceMode        : AVCaptureDevice.WhiteBalanceMode     = SmileIDSingleton.sharedInstance.whiteBalanceMode
    
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
    func fromJsonDict( dict : Dictionary<String,Any> ) -> LensCharacteristics? {
        let jsonUtils = JsonUtils()
        
        flashMode = jsonUtils.getString(dict:dict,
            key: LensCharacteristics.KEY_FLASH_MODE,
            defaultVal : "" )
        
        focalLength = jsonUtils.getFloat(dict:dict,
            key: LensCharacteristics.KEY_FOCAL_LENGTH,
            defaultVal : 0.0 )
        
        // Read array of arrays ( Ported from Android code this way,
        // in order to maintain compatibility with the format
        // var jsFpsRangeArray = [Any]()

        var jsFpsRangeArray = jsonUtils.getArray(dict:dict,
            key: LensCharacteristics.KEY_FPS_RANGE,
            defaultVal: [Any]() )
        
        // var fpsRangeArray = [Any]()
        var fpsRangeArray = [jsFpsRangeArray[0]]
        
        fpsRange = FPSRange( min:fpsRangeArray[0] as! Int,
                             max:fpsRangeArray[1] as! Int)
        
        
        horizontalViewAngle = jsonUtils.getFloat(dict:dict,
            key: LensCharacteristics.KEY_HORIZONTAL_VIEW_ANGLE,
            defaultVal : 0.0 )
        
        verticalViewAngle = jsonUtils.getFloat(dict:dict,
            key: LensCharacteristics.KEY_VERTICAL_VIEW_ANGLE,
            defaultVal : 0.0 )
        
        jpegQuality = jsonUtils.getInt(dict:dict,
            key: LensCharacteristics.KEY_JPEG_QUALITY,
            defaultVal : 0 )
        
        jpegThumbnailQuality = jsonUtils.getInt(dict:dict,
            key: LensCharacteristics.KEY_JPEG_THUMBNAIL_QUALITY,
            defaultVal : 0 )
        
        maxFPS = jsonUtils.getInt(dict:dict,
            key: LensCharacteristics.KEY_MAX_FPS,
            defaultVal : 0 )
        
        minFPS = jsonUtils.getInt(dict:dict,
            key: LensCharacteristics.KEY_MIN_FPS,
            defaultVal : 0 )
        
        devicePortraitHorizontalResolution = jsonUtils.getInt(dict:dict,
            key: LensCharacteristics.KEY_MAX_PREVIEW_WIDTH,
            defaultVal : 0 )
        
        devicePortraitVerticalResolution = jsonUtils.getInt(dict:dict,
            key: LensCharacteristics.KEY_MAX_PREVIEW_HEIGHT,
            defaultVal : 0 )
        
        maxZoom = jsonUtils.getInt(dict:dict,
            key: LensCharacteristics.KEY_MAX_ZOOM,
            defaultVal : 0 )
        
        let sWhiteBalanceMode = jsonUtils.getString(dict:dict,
            key: LensCharacteristics.KEY_WHITE_BALANCE,
            defaultVal : "auto" )
        whiteBalanceMode = whiteBalanceModeFromString(sWhiteBalanceMode: sWhiteBalanceMode )
        
        return self

    }
    
    func fromJsonString( jsonFormattedString : String ) -> LensCharacteristics? {
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
        
        jsonUtils.putString( dict: &dict, key: LensCharacteristics.KEY_FLASH_MODE,
                             val: flashMode )
        
        jsonUtils.putFloat( dict: &dict, key: LensCharacteristics.KEY_FOCAL_LENGTH,
                            val: focalLength )
        
        /* Ported from Android code, so that the format is compatible
         with the old code */
        // Create an array of arrays for the fps ranges.
        // First, create one FPSRange object.
        let fpsRange = FPSRange( min:
            SmileIDSingleton.sharedInstance.minFPS,
                                 max:SmileIDSingleton.sharedInstance.maxFPS )
        // Each FPSRange goes into an array, where [0] = min, and [1] = max
        var fpsRangeArray = [Any]()
        fpsRangeArray[0] = fpsRange.min
        fpsRangeArray[1] = fpsRange.max
        
        // Now create an array of fpsRanges.
        // In this case there is only one.
        var jsFpsRangeArray = [Any]()
        jsFpsRangeArray[0] = fpsRangeArray
        
        // Now put jsFpsRangeArray in the dictionary
        jsonUtils.putArray(dict: &dict, key: LensCharacteristics.KEY_FPS_RANGE, val:jsFpsRangeArray)
        
        jsonUtils.putFloat( dict: &dict, key: LensCharacteristics.KEY_HORIZONTAL_VIEW_ANGLE,
                            val: horizontalViewAngle )
        
        jsonUtils.putFloat( dict: &dict, key: LensCharacteristics.KEY_VERTICAL_VIEW_ANGLE,
                            val: verticalViewAngle )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_JPEG_QUALITY,
                          val: jpegQuality )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_JPEG_THUMBNAIL_QUALITY,
                          val: jpegThumbnailQuality )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MAX_FPS,
                          val: maxFPS )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MIN_FPS,
                          val: minFPS )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MAX_PREVIEW_WIDTH,
                          val: devicePortraitHorizontalResolution )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MAX_PREVIEW_HEIGHT,
                          val: devicePortraitVerticalResolution )
        
        jsonUtils.putInt( dict: &dict, key: LensCharacteristics.KEY_MAX_ZOOM,
                          val:maxZoom )
        
        let sWhiteBalanceMode = whiteBalanceModeToString( whiteBalanceMode:whiteBalanceMode  )
        jsonUtils.putString( dict: &dict, key: LensCharacteristics.KEY_WHITE_BALANCE,
            val : sWhiteBalanceMode )
                             
        
        return dict
    }
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
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
    
    func whiteBalanceModeFromString( sWhiteBalanceMode : String ) -> AVCaptureDevice.WhiteBalanceMode {
        
        if( sWhiteBalanceMode == "locked" ){
            return AVCaptureDevice.WhiteBalanceMode.locked
        }
        else if( sWhiteBalanceMode == "auto"  ){
            return AVCaptureDevice.WhiteBalanceMode.autoWhiteBalance
        }
        else{
            return AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance
        }
    }

}
