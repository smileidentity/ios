//
//  SIDNetworkRequestDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

protocol SIDNetworkRequestDelegate {
    func onComplete()
    func onError( errMsg : String )
    func onUpdate( progress : Int )
    func onAuthenticated( response : SIDResponse )
    func onEnrolled( response : SIDResponse )
}

