//
//  CapturedImage.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class CapturedImage{
    var nonceStep       : Int?
    var filename        : String?
    var fullFrameInfo  : FullFrameInfo?
    
    init( filename : String,  fullFrameInfo : FullFrameInfo ) {
        self.filename = filename;
        self.fullFrameInfo = fullFrameInfo;
    }
}
