//
//  CaptureIDCardDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/16/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

protocol CaptureIDCardDelegate {
    func onComplete( previewUIImage : UIImage )
    func onError( sidError : SIDError )
}
