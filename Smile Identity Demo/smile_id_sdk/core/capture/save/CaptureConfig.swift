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

     static let KEY_USE_ARC                     : String = "useArc"
    static let KEY_USE_EMOTICON                 : String = "useEmoticon"
    
    /*
     Ported from Android code to keep the JSON format the same.
     Most of these settings are not used on iOS.
     */
    
     
    let idCardDelay         : Int = 5
    let acceptBox           : String = "Create Smile Identity"
    let autoSend            : Bool = false
    let showXmitProgress    : Bool = true
    let consentMessage      : String = "Smile Identity helps us to verify your identity. By using this service you comply with the Terms of use."
    
    let desiredHeight       : Int = 240
    let desiredWidth        : Int = 320
    let disableRestart      : Bool = true
    let idCardMessage1      : String = "Place your ID within the rectangle and TAP the Screen"
    let idCardMessage2      : String = "Please tap inside the rectangular bound"
    
    let idCardMessage3     : String = "Can you read the complete ID?"
    var idCardType          : String = ""
    let imageFormat         : Int = 4
    var imageProcessingCaps = ImageProcessingCaps()
    let isCaptureFullImage  : Bool = false
    let isFrontFacingCamera : Bool = true
    let manualCapture       : Bool = false
    let maxArcWidth         : Int = 10
    let maxFPS              : Int = 5
    let maxFrameTimeout     : Int = 120
    let minArcWidth         : Int = 10
    let minSmileConfidence  : Float = 0.8
    let minX                : Int = 128
    let minY                : Int = 128
    let numImagesToCapture  : Int = 8
    let onPreview           : Bool = false
    
    /* These are reset in PackageService */
    var lambdaAddress       : String = "https://3eydmgh10d.execute-api.us-west-2.amazonaws.com/test/upload"
    var partnerAddress      : String = "https://test-smileid.herokuapp.com/"
    var partnerPort         : String = "8080"
    var sidAddress          : String = "smileidentity"
    var sidPort             : String = "8443"
    
    let scalingFullCapture  : Int = 4
    let scalingIdCard       : Int = 2
    let scalingMinDimen     : Int = 640
    let scalingOffset       : Int = 0
    let scalingQuality      : Int = 100
     let suggestedFPS        : Int = 5
    let toastDelay          : Int = 1000
    let toastDelayForSamePrompt : Int = 100
    let toastFaceInOval     : String = "Put Your Face Inside Oval"
    let toastMoveCloser     : String = "Move Closer"
    let toastSmile          : String = "Smile"
    let toastSmileMore      : String = "Smile More"
    let useArc              : Bool = true
    let useEmoticon         : Bool = false

     
    
    
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
                           val:ImageProcessingCaps().toJsonDict()
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
