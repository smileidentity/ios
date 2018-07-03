//
//  SIDResponse.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/22/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDResponse {
    var partnerParams       : PartnerParams?
    var success             : Bool?
    var confidenceValue     : Float?
    
    init( partnerParams     : PartnerParams?,
          success           : Bool,
          confidenceValue   : Float ) {
        self.partnerParams      = partnerParams
        self.success            = success
        self.confidenceValue    = confidenceValue
        
    }
}
