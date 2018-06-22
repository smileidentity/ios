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
    /* if successfull, sidError param will be SIDError.SUCCESS,
        if failed, sidError param will contain the error */
    func onServiceFinished( sidError : SIDError,
                            confidenceValue : Float,
                            retry : Bool,
                            partnerParams : PartnerParams? )
    func onUpdateJobStatus( msg : String )
    func onError( sidError : SIDError )
}
