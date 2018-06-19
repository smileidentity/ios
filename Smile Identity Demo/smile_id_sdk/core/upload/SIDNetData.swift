//
//  SIDNetData.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/23/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDNetData {
    
    var authUrl     : String = ""
    var partnerUrl  : String = ""
    var partnerPort : String = ""
    var lambdaUrl   : String = ""
    var jobStatusUrl: String = ""
    var sidAddress  : String = ""
    var sidPort     : String = ""
    
    func insertPartnerId( partnerId : String ) -> String {
        if( jobStatusUrl.isEmpty ){
            return ""
        }
        else{
            return jobStatusUrl.replacingOccurrences(of: "#", with: partnerId, options: .literal, range: nil)
        }
    }
    
 
}
