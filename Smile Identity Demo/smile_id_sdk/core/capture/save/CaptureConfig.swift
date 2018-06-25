//
//  CaptureConfig.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/12/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation


class CaptureConfig {
    
    static let KEY_ID_CARD_DELAY            : String = "IDCardDelay"
    static let KEY_ACCEPT_BOX               : String = "acceptBox"
    static let KEY_AUTO_SEND                : String = "bAutoSend"
    static let KEY_SHOW_XMIT_PROGRESS        : String = "bShowXmitProgress"
    static let KEY_CONSENT_MESSAGE          : String = "consentMessage"
    static let KEY_DESIRED_HEIGHT           : String = "desiredHeight"
    static let KEY_DESIRED_WIDTH            : String = "desiredWidth"
    static let KEY_DISABLE_RESTART          : String = "disableRestart"
    static let KEY_ID_CARD_MESSAGE1         : String = "idCardMessage1"
    static let KEY_ID_CARD_MESSAGE2         : String = "idCardMessage2"
    static let KEY_ID_CARD_MESSAGE3         : String = "idCardMessage3"
    static let KEY_ID_CARD_TYPE             : String = "idCardType"
    static let KEY_IMAGE_FORMAT             : String = "imageFormat"
    static let KEY_IMAGE_PROCESSING_CAPS    : String = "imageProcessingCaps"
    static let KEY_IS_CAPTURE_FULL_IMAGE    : String = "isCaptureFullImage"
    static let KEY_IS_FRONT_FACING_CAMERA   : String = "isFrontFacingCamera"
    static let KEY_LAMBDA_ADDRESS           : String = "lambdaAddress"
    static let KEY_MANUAL_CAPTURE           : String = "manualCapture"
    static let KEY_MAX_ARC_WIDTH            : String = "maxArcWidth"
    static let KEY_MAX_FPS                  : String = "maxFPS"
    static let KEY_MAX_FRAME_TIMEOUT        : String = "maxFrameTimeout"
    static let KEY_MIN_ARC_WIDTH            : String = "minArcWidth"
    static let KEY_MIN_SMILE_CONFIDENCE    : String = "minSmileConfidence"
    static let KEY_MIN_X                     : String = "minX"
    static let KEY_MIN_Y                     : String = "minY"
    static let KEY_NUM_IMAGES_TO_CAPTURE    : String = "numImagesToCapture"
    static let KEY_ON_PREVIEW               : String = "onPreview"
    static let KEY_PARTNER_ADDRESS          : String = "partnerAddress"
    static let KEY_PARTNER_PORT             : String = "partnerPort"
    static let KEY_SCALING_FULL_CAPTURE     : String = "scalingFullCapture"
    static let KEY_SCALING_ID_CARD          : String = "scalingIDCard"
    static let KEY_SCALING_MIN_DIMEN        : String = "scalingMinDimen"
    static let KEY_SCALING_OFFSET           : String = "scalingOffset"
    static let KEY_SCALING_QUALITY          : String = "scalingQuality"
    static let KEY_SID_ADDRESS              : String = "sidAddress"
    static let KEY_SID_PORT                 : String = "sidPort"
    static let KEY_SUGGESTED_FPS            : String = "suggestedFPS"
    static let KEY_TOAST_DELAY              : String = "toastDelay"
    static let KEY_TOAST_DELAY_FOR_SAME_PROMPT              : String = "toastDelayForSamePrompt"
    static let KEY_TOAST_FACE_IN_OVAL           : String = "toastFaceInOval"
    static let KEY_TOAST_MOVE_CLOSER            : String = "toastMoveCloser"
    static let KEY_TOAST_SMILE                  : String = "toastSmile"
    
    static let KEY_TOAST_SMILE_MORE             : String = "toastSmileMore"

    static let KEY_USE_ARC                      : String = "useArc"
    static let KEY_USE_EMOTICON                 : String = "useEmoticon"
    
    /*
     Ported from Android code to keep the JSON format the same.
     Most of these settings are not used on iOS.
     */
    
    static let DEFAULT_ID_CARD_DELAY        = 5
    static let DEFAULT_ACCEPT_BOX           = "Create Smile Identity"
    static let DEFAULT_AUTO_SEND            = false
    static let DEFAULT_SHOW_XMIT_PROGRESS   = true
    static let DEFAULT_CONSENT_MESSAGE      = "Smile Identity helps us to verify your identity. By using this service you comply with the Terms of use."
    
    static let DEFAULT_DESIRED_HEIGHT       = 240
    static let DEFAULT_DESIRED_WIDTH        = 320
    static let DEFAULT_DISABLE_RESTART      = true
    
    static let DEFAULT_ID_CARD_MESSAGE_1    = "Place your ID within the rectangle and TAP the Screen"
    static let DEFAULT_ID_CARD_MESSAGE_2    = "Please tap inside the rectangular bound"
    static let DEFAULT_ID_CARD_MESSAGE_3    = "Can you read the card ID?"
    
    static let DEFAULT_ID_CARD_TYPE         = ""
    static let DEFAULT_IMAGE_FORMAT         = 4
    static let DEFAULT_CAPTURE_FULL_IMAGE   = false
    static let DEFAULT_IS_FRONT_FACING_CAMERA = true
    static let DEFAULT_LAMBDA_ADDRESS       = "https://3eydmgh10d.execute-api.us-west-2.amazonaws.com/test/upload"
    static let DEFAULT_PARTNER_ADDRESS      = "https://test-smileid.herokuapp.com/"
    static let DEFAULT_PARTNER_PORT         = "8080"
    static let DEFAULT_SID_ADDRESS          = "smileidentity"
    static let DEFAULT_SID_PORT             = "8443"
    
    static let DEFAULT_MANUAL_CAPTURE       = false
    static let DEFAULT_MAX_ARC_WIDTH        = 10
    static let DEFAULT_MAX_FPS              = 5
    static let DEFAULT_MAX_FRAME_TIMEOUT    = 120
    static let DEFAULT_MIN_ARC_WIDTH        = 10
    static let DEFAULT_MIN_SMILE_CONFIDENCE : Float = 0.8
    static let DEFAULT_MIN_X                = 128
    static let DEFAULT_MIN_Y                = 128
    static let DEFAULT_NUM_IMAGES_TO_CAPTURE = 8
    static let DEFAULT_ON_PREVIEW           = false
    static let DEFAULT_SCALING_FULL_CAPTURE = 4
    static let DEFAULT_SCALING_ID_CARD      = 2
    static let DEFAULT_SCALING_MIN_DIM      = 640
    static let DEFAULT_SCALING_OFFSET       = 0
    static let DEFAULT_SCALING_QUALITY      = 100
    static let DEFAULT_SUGGESTED_FPS        = 5
    static let DEFAULT_TOAST_DELAY          = 1000
    static let DEFAULT_TOAST_DELAY_FOR_SAME_PROMPT = 100
    static let DEFAULT_TOAST_FACE_IN_OVAL   = "Put Your Face Inside Oval"
    static let DEFAULT_TOAST_MOVE_CLOSER    = "Move Closer"
    static let DEFAULT_TOAST_SMILE          = "Smile"
    static let DEFAULT_TOAST_SMILE_MORE     = "Smile More"
    static let DEFAULT_USE_ARC              = true
    static let DEFAULT_USE_EMOTICON         = false
    
    var idCardDelay         : Int       = DEFAULT_ID_CARD_DELAY
    var acceptBox           : String    = DEFAULT_ACCEPT_BOX
    var autoSend            : Bool      = DEFAULT_AUTO_SEND
    var showXmitProgress    : Bool      = DEFAULT_SHOW_XMIT_PROGRESS
    var consentMessage      : String    = DEFAULT_CONSENT_MESSAGE
    
    var desiredHeight       : Int       = DEFAULT_DESIRED_HEIGHT
    var desiredWidth        : Int       = DEFAULT_DESIRED_WIDTH
    
    var disableRestart      : Bool      = DEFAULT_DISABLE_RESTART
    var idCardMessage1      : String    = DEFAULT_ID_CARD_MESSAGE_1
    var idCardMessage2      : String    = DEFAULT_ID_CARD_MESSAGE_2
    var idCardMessage3      : String    = DEFAULT_ID_CARD_MESSAGE_3
    
    var idCardType          : String    = DEFAULT_ID_CARD_TYPE
    var imageFormat         : Int       = DEFAULT_IMAGE_FORMAT
    var imageProcessingCaps = ImageProcessingCaps()
    
    var isCaptureFullImage  : Bool      = DEFAULT_CAPTURE_FULL_IMAGE
    var isFrontFacingCamera : Bool      = DEFAULT_IS_FRONT_FACING_CAMERA
    var manualCapture       : Bool      = DEFAULT_MANUAL_CAPTURE
    var maxArcWidth         : Int       = DEFAULT_MAX_ARC_WIDTH
    var maxFPS              : Int       = DEFAULT_MAX_FPS
    var maxFrameTimeout     : Int       = DEFAULT_MAX_FRAME_TIMEOUT
    var minArcWidth         : Int       = DEFAULT_MIN_ARC_WIDTH
    var minSmileConfidence  : Float     = DEFAULT_MIN_SMILE_CONFIDENCE
    var minX                : Int       = DEFAULT_MIN_X
    var minY                : Int       = DEFAULT_MIN_Y
    var numImagesToCapture  : Int       = DEFAULT_NUM_IMAGES_TO_CAPTURE
    var onPreview           : Bool      = DEFAULT_ON_PREVIEW
    
    /* These are reset in PackageService */
    var lambdaAddress       : String = DEFAULT_LAMBDA_ADDRESS
    var partnerAddress      : String = DEFAULT_PARTNER_ADDRESS
    var partnerPort         : String = DEFAULT_PARTNER_PORT
    var sidAddress          : String = DEFAULT_SID_ADDRESS
    var sidPort             : String = DEFAULT_SID_PORT
    
    var scalingFullCapture  : Int   = DEFAULT_SCALING_FULL_CAPTURE
    var scalingIdCard       : Int   = DEFAULT_SCALING_ID_CARD
    var scalingMinDimen     : Int   = DEFAULT_SCALING_MIN_DIM
    var scalingOffset       : Int   = DEFAULT_SCALING_OFFSET
    var scalingQuality      : Int   = DEFAULT_SCALING_QUALITY
    var suggestedFPS        : Int   = DEFAULT_SUGGESTED_FPS
    var toastDelay          : Int   = DEFAULT_TOAST_DELAY
    var toastDelayForSamePrompt : Int = 100
    var toastFaceInOval     : String    = DEFAULT_TOAST_FACE_IN_OVAL
    var toastMoveCloser     : String    = DEFAULT_TOAST_MOVE_CLOSER
    var toastSmile          : String    = DEFAULT_TOAST_SMILE
    var toastSmileMore      : String    = DEFAULT_TOAST_SMILE_MORE
    var useArc              : Bool      = DEFAULT_USE_ARC
    var useEmoticon         : Bool      = DEFAULT_USE_EMOTICON
    
    func fromJsonDict( dict : Dictionary<String,Any> ) -> CaptureConfig? {
        let jsonUtils = JsonUtils()
        
        idCardDelay = jsonUtils.getInt(dict:dict,
                            key: CaptureConfig.KEY_ID_CARD_DELAY,
                            defaultVal: CaptureConfig.DEFAULT_ID_CARD_DELAY )

        acceptBox = jsonUtils.getString(dict:dict,
                            key: CaptureConfig.KEY_ACCEPT_BOX,
                            defaultVal: CaptureConfig.DEFAULT_ACCEPT_BOX )
        
        autoSend = jsonUtils.getBool(dict:dict,
                            key: CaptureConfig.KEY_AUTO_SEND,
                            defaultVal: CaptureConfig.DEFAULT_AUTO_SEND )
        
        showXmitProgress = jsonUtils.getBool(dict:dict,
                            key: CaptureConfig.KEY_SHOW_XMIT_PROGRESS,
                            defaultVal : CaptureConfig.DEFAULT_SHOW_XMIT_PROGRESS )
        
        consentMessage = jsonUtils.getString(dict:dict,
                            key: CaptureConfig.KEY_CONSENT_MESSAGE,
                            defaultVal: CaptureConfig.DEFAULT_CONSENT_MESSAGE )
        
        desiredHeight = jsonUtils.getInt(dict:dict,
                            key: CaptureConfig.KEY_DESIRED_HEIGHT,
                            defaultVal: CaptureConfig.DEFAULT_DESIRED_HEIGHT )
        
        desiredWidth = jsonUtils.getInt(dict:dict,
                            key: CaptureConfig.KEY_DESIRED_WIDTH,
                            defaultVal: CaptureConfig.DEFAULT_DESIRED_WIDTH )
        
        disableRestart = jsonUtils.getBool(dict:dict,
                        key: CaptureConfig.KEY_DISABLE_RESTART,
                        defaultVal: CaptureConfig.DEFAULT_DISABLE_RESTART )
        
        idCardMessage1 = jsonUtils.getString(dict:dict,
                        key: CaptureConfig.KEY_ID_CARD_MESSAGE1,
                        defaultVal: CaptureConfig.DEFAULT_ID_CARD_MESSAGE_1 )
        
        idCardMessage2 = jsonUtils.getString(dict:dict,
                        key: CaptureConfig.KEY_ID_CARD_MESSAGE2,
                        defaultVal: CaptureConfig.DEFAULT_ID_CARD_MESSAGE_2 )
        
        idCardMessage3 = jsonUtils.getString(dict:dict,
                        key: CaptureConfig.KEY_ID_CARD_MESSAGE3,
                        defaultVal: CaptureConfig.DEFAULT_ID_CARD_MESSAGE_3 )
        
        idCardType = jsonUtils.getString(dict:dict,
                        key: CaptureConfig.KEY_ID_CARD_TYPE,
                        defaultVal: CaptureConfig.DEFAULT_ID_CARD_TYPE )
        
        idCardType = jsonUtils.getString(dict:dict,
                        key: CaptureConfig.KEY_IMAGE_FORMAT,
                        defaultVal:"" )
        
        imageFormat = jsonUtils.getInt(dict:dict,
                    key: CaptureConfig.KEY_IMAGE_FORMAT,
                    defaultVal: CaptureConfig.DEFAULT_IMAGE_FORMAT )
        
        let sImageProcessingCaps =
            jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_IMAGE_PROCESSING_CAPS,
            defaultVal : "" )
        imageProcessingCaps = ImageProcessingCaps()
        if( !sImageProcessingCaps.isEmpty ){
            imageProcessingCaps = imageProcessingCaps.fromJsonString(jsonFormattedString: sImageProcessingCaps )!
        }
        
        isCaptureFullImage = jsonUtils.getBool(dict:dict,
            key: CaptureConfig.KEY_IS_CAPTURE_FULL_IMAGE,
            defaultVal: CaptureConfig.DEFAULT_CAPTURE_FULL_IMAGE )
        
        isFrontFacingCamera = jsonUtils.getBool(dict:dict,
            key: CaptureConfig.KEY_IS_FRONT_FACING_CAMERA,
            defaultVal: CaptureConfig.DEFAULT_IS_FRONT_FACING_CAMERA )
        
        lambdaAddress = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_LAMBDA_ADDRESS,
            defaultVal: CaptureConfig.DEFAULT_LAMBDA_ADDRESS )

        manualCapture = jsonUtils.getBool(dict:dict,
            key: CaptureConfig.KEY_MANUAL_CAPTURE,
            defaultVal: CaptureConfig.DEFAULT_MANUAL_CAPTURE )

        maxArcWidth = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_MAX_ARC_WIDTH,
            defaultVal: CaptureConfig.DEFAULT_MAX_ARC_WIDTH )

        maxFPS = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_MAX_FPS,
            defaultVal: CaptureConfig.DEFAULT_MAX_FPS )

        maxFrameTimeout = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_MAX_FRAME_TIMEOUT,
            defaultVal: CaptureConfig.DEFAULT_MAX_FRAME_TIMEOUT )

        minArcWidth = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_MIN_ARC_WIDTH,
            defaultVal: CaptureConfig.DEFAULT_MIN_ARC_WIDTH )
        
        minSmileConfidence = jsonUtils.getFloat(dict:dict,
            key: CaptureConfig.KEY_MIN_SMILE_CONFIDENCE,
            defaultVal: CaptureConfig.DEFAULT_MIN_SMILE_CONFIDENCE )
        
        minX = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_MIN_X,
            defaultVal: CaptureConfig.DEFAULT_MIN_X )
        
        minY = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_MIN_Y,
            defaultVal: CaptureConfig.DEFAULT_MIN_Y )
        
        numImagesToCapture = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_NUM_IMAGES_TO_CAPTURE,
            defaultVal: CaptureConfig.DEFAULT_NUM_IMAGES_TO_CAPTURE )
        
        onPreview = jsonUtils.getBool(dict:dict,
            key: CaptureConfig.KEY_ON_PREVIEW,
            defaultVal : CaptureConfig.DEFAULT_ON_PREVIEW )
        
        partnerAddress = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_PARTNER_ADDRESS,
            defaultVal: CaptureConfig.DEFAULT_PARTNER_ADDRESS )
        
        partnerPort = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_PARTNER_PORT,
            defaultVal: CaptureConfig.DEFAULT_PARTNER_PORT )
        
        sidAddress = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_SID_ADDRESS,
            defaultVal: CaptureConfig.DEFAULT_SID_ADDRESS )
        
        sidPort = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_SID_PORT,
            defaultVal: CaptureConfig.DEFAULT_SID_PORT )
        
        scalingFullCapture = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_SCALING_FULL_CAPTURE,
            defaultVal: CaptureConfig.DEFAULT_SCALING_FULL_CAPTURE )
        
        scalingIdCard = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_SCALING_ID_CARD,
            defaultVal: CaptureConfig.DEFAULT_SCALING_ID_CARD )
        
        scalingMinDimen = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_SCALING_MIN_DIMEN,
            defaultVal: CaptureConfig.DEFAULT_SCALING_MIN_DIM )
        
        scalingOffset = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_SCALING_OFFSET,
            defaultVal: CaptureConfig.DEFAULT_SCALING_OFFSET )
        
        scalingQuality = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_SCALING_QUALITY,
            defaultVal: CaptureConfig.DEFAULT_SCALING_QUALITY )
       
        suggestedFPS = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_SUGGESTED_FPS,
            defaultVal: CaptureConfig.DEFAULT_SUGGESTED_FPS )
        
        toastDelay = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_TOAST_DELAY,
            defaultVal: CaptureConfig.DEFAULT_TOAST_DELAY )
        
        toastDelayForSamePrompt = jsonUtils.getInt(dict:dict,
            key: CaptureConfig.KEY_TOAST_DELAY_FOR_SAME_PROMPT,
            defaultVal: CaptureConfig.DEFAULT_TOAST_DELAY_FOR_SAME_PROMPT )
        
        toastFaceInOval = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_TOAST_FACE_IN_OVAL,
            defaultVal: CaptureConfig.DEFAULT_TOAST_FACE_IN_OVAL )
        
        toastMoveCloser = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_TOAST_MOVE_CLOSER,
            defaultVal: CaptureConfig.DEFAULT_TOAST_MOVE_CLOSER )

        toastSmile = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_TOAST_SMILE,
            defaultVal: CaptureConfig.DEFAULT_TOAST_SMILE )
        
        toastSmileMore = jsonUtils.getString(dict:dict,
            key: CaptureConfig.KEY_TOAST_SMILE_MORE,
            defaultVal: CaptureConfig.DEFAULT_TOAST_SMILE_MORE )
        
        useArc = jsonUtils.getBool(dict:dict,
            key: CaptureConfig.KEY_USE_ARC,
            defaultVal: CaptureConfig.DEFAULT_USE_ARC )
        
        useEmoticon = jsonUtils.getBool(dict:dict,
            key: CaptureConfig.KEY_USE_EMOTICON,
            defaultVal: CaptureConfig.DEFAULT_USE_EMOTICON )

        return self
        
        
    }
     
    
    
    func fromJsonString( jsonFormattedString : String ) -> CaptureConfig? {
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
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_ID_CARD_DELAY,
                          val:idCardDelay )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_ACCEPT_BOX,
                             val:acceptBox )
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_AUTO_SEND,
                           val:autoSend )
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_SHOW_XMIT_PROGRESS,
                           val:showXmitProgress )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_CONSENT_MESSAGE,
                             val:consentMessage )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_DESIRED_HEIGHT,
                          val:desiredHeight )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_DESIRED_WIDTH,
                          val:desiredWidth)
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_DISABLE_RESTART,
                           val:disableRestart)
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_ID_CARD_MESSAGE1,
                             val:idCardMessage1 )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_ID_CARD_MESSAGE2,
                             val:idCardMessage2 )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_ID_CARD_MESSAGE3,
                             val:idCardMessage3 )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_ID_CARD_TYPE,
                             val:idCardType )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_IMAGE_FORMAT,
                          val:imageFormat )
        
        jsonUtils.putDict( dict: &dict, key: CaptureConfig.KEY_IMAGE_PROCESSING_CAPS,
                           val:imageProcessingCaps.toJsonDict()
        )
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_IS_CAPTURE_FULL_IMAGE,
                           val:isCaptureFullImage )
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_IS_FRONT_FACING_CAMERA,
                           val:isFrontFacingCamera )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_LAMBDA_ADDRESS,
                             val:lambdaAddress )
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_MANUAL_CAPTURE,
                           val:manualCapture )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_MAX_ARC_WIDTH,
                          val:maxArcWidth )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_MAX_FPS,
                          val:maxFPS )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_MAX_FRAME_TIMEOUT,
                          val:maxFrameTimeout )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_MIN_ARC_WIDTH,
                          val:minArcWidth )
        
        jsonUtils.putFloat( dict: &dict, key: CaptureConfig.KEY_MIN_SMILE_CONFIDENCE,
                            val:minSmileConfidence )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_MIN_X,
                          val:minX )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_MIN_Y,
                          val:minY )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_NUM_IMAGES_TO_CAPTURE,
                          val:numImagesToCapture )
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_ON_PREVIEW,
                           val:onPreview )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_PARTNER_ADDRESS,
                             val:partnerAddress )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_PARTNER_PORT,
                             val:partnerPort )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_SCALING_FULL_CAPTURE,
                          val:scalingFullCapture )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_SCALING_ID_CARD,
                          val:scalingIdCard )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_SCALING_MIN_DIMEN,
                          val:scalingMinDimen )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_SCALING_OFFSET,
                          val:scalingOffset )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_SCALING_QUALITY,
                          val:scalingQuality )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_SID_ADDRESS,
                             val:sidAddress )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_SID_PORT,
                             val:sidPort )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_SUGGESTED_FPS,
                          val:suggestedFPS )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_TOAST_DELAY,
                          val:toastDelay )
        
        jsonUtils.putInt( dict: &dict, key: CaptureConfig.KEY_TOAST_DELAY_FOR_SAME_PROMPT,
                          val:toastDelayForSamePrompt )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_TOAST_FACE_IN_OVAL,
                             val:toastFaceInOval )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_TOAST_MOVE_CLOSER,
                             val:toastMoveCloser )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_TOAST_SMILE,
                             val:toastSmile )
        
        jsonUtils.putString( dict: &dict, key: CaptureConfig.KEY_TOAST_SMILE_MORE,
                             val:toastSmileMore )
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_USE_ARC,
                           val:useArc )
        
        jsonUtils.putBool( dict: &dict, key: CaptureConfig.KEY_USE_EMOTICON,
                           val:useEmoticon )
        
        return dict
        
    }
    
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
        
    }
    
    
    
}
