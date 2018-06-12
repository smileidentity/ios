//
//  FaceDetectorConstants.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/4/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

struct FaceDetectorConstants {
     
    // Face States
    static let NO_FACE_FOUND                    = 0
    static let DO_MOVE_CLOSER                   = 1
    static let DO_SMILE                         = 2
    static let DO_SMILE_MORE                    = 3
    static let CAPTURING                        = 4

    // Frame States
    static let FRAME_STATE_CAPTURING            = 0
     
    static let FACE_MARGIN                      : CGFloat = 10.0
    static let CROP_FACE_GRAPHIC_MULTIPLE_VALUE : Int = 4
  
}
