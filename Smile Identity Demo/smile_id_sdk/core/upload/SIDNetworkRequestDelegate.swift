//
//  SIDNetworkRequestDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

protocol SIDNetworkRequestDelegate {
    
    func onStartJobStatus()
    func onEndJobStatus()
    func onUpdateJobProgress( progress : Int )
    func onUpdateJobStatus( msg : String )

    func onAuthenticated( sidResponse : SIDResponse )
    func onEnrolled( sidResponse : SIDResponse )
    func onComplete()
    func onError( sidError : SIDError  )

    
}

