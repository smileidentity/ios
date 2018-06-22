//
//  UploadServiceDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/20/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

/*
    Communicate from UploadService back to SIDNetworkRequest
*/
protocol UploadServiceDelegate {
    func onStartJobStatus()
    func onEndJobStatus()
    func onError( sidError : SIDError )
}
