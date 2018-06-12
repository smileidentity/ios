//
//  SIDMetadata.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/29/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation


class SIDMetadata {
    
    var partnerParams : PartnerParams?
    var sidUserIdInfo : SIDUserIdInfo?
    
    init() {
        partnerParams = PartnerParams()
        sidUserIdInfo = SIDUserIdInfo()
        
    }
    
}
