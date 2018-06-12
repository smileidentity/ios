//
//  SmileIDSingleton.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/10/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import AVFoundation

class SmileIDSingleton {
    static let sharedInstance = SmileIDSingleton()
    
    // Selfie response codes
    static let SELFIE_RESPONSE_CODE_SUCCESS             = 0
    static let SELFIE_RESPONSE_CODE_MAX_FRAME_TIMEOUT   = 1
    
    static let PREVIEW_FRAME_NAME = "SID_Preview_Full.jpg";
    // ID card Image name
    static let ID_CARD_FRAME_NAME = "SID_IDCard.jpg";
    // from SMILEID
    static let FB_USER_FRAME_NAME = "SID_FBUser.jpg"; // FB Use
    
    // ported from Misc class in the Android project
    static let USER_TAG =  "USER_TAG_3"
    
    var selfieImageUI   : Data?
    var framesList      : [FrameData] = []
    var previewFrame    : FrameData?
    var idCardFrame     : FrameData?
    
    var fbUserImage     : Data?
    
    /* camera settings */
    var lensCharacteristicsFront            = LensCharacteristics()
    var lensCharacteristicsBack             = LensCharacteristics()
    var selfieCameraExists                  : Bool = false
    var devicePortraitHorizontalResolution  : Int = 0
    var devicePortraitVerticalResolution    : Int = 0
    var minFPS                              : Int = 0
    var maxFPS                              : Int = 0
    var whiteBalanceMode                     = AVCaptureDevice.WhiteBalanceMode.autoWhiteBalance
    
    let capturedImagesManager   = CapturedImagesManager()
   
    func setFramesList( framesList : [FrameData]){self.framesList = framesList}
    func getFramesList() -> [FrameData] { return self.framesList }
    
 
    
    
    
    
}

