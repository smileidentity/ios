//
//  NetRequestDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/31/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

protocol NetRequestDelegate {
    func onUploadProgress( progress : Int )
    func onUpdateJobStatus( msg : String )
}

