//
//  MetaData.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class MetaData {
    var referenceId : String?
    var apiVersion  : APIVersion?
    
    var sidDeviceCameraInfosFront   : SIDCameraInfos?
    var sidDeviceCameraInfosBack    : SIDCameraInfos?
    
    var securityCaps                : SecurityCaps?
    var frameInfo                   : [FullFrameInfo]?
    var frameInfoPreviewFull        : FullFrameInfo?
    var frameInfoIDCard             : FullFrameInfo?
    var isMaxFrameTimeout           : Bool?
    
    
  
}
