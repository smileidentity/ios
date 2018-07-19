//
//  CaptureSelfieDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/8/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

protocol CaptureSelfieDelegate {
    // func onTestDisplayImage( uiImage : UIImage )
    func onComplete( previewUIImage : UIImage )
    func onError( sidError : SIDError )
}

