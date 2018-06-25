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
    func onUpdateServiceComplete( sidError : SIDError,
                            confidenceValue : Float,
                            retryFlag : Bool,
                            partnerParams : PartnerParams? )
    func onUpdateJobStatus( msg : String )
    func onUpdateJobProgress( progress : Int )
    func onUpdateError( sidError : SIDError,
                        confidenceValue : Float,
                        retryFlag : Bool,
                        partnerParams : PartnerParams? )
}
