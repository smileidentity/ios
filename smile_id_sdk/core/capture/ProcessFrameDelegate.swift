//
//  ProcessFrameDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/8/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

protocol ProcessFrameDelegate {
    func onProcessFrame( frameState : Int,
                         pixelBuffer : CVImageBuffer,
                         faceRect : CGRect,
                         hasSmile : Bool )
}
