//
//  SIDNetData.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/23/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDNetData {
    
    let PARTNER_ID = "003";
    
    var authUrl     : String = ""
    var partnerUrl  : String = ""
    var partnerPort : String = ""
    var lambdaUrl   : String = ""
    var jobStatusUrl: String = ""
    var sidAddress  : String = ""
    var sidPort     : String = ""
    
    func insertPartnerId( urlString : String ) -> String {
        if( urlString.isEmpty ){
            return ""
        }
        else{
            return urlString.replacingOccurrences(of: "#", with: PARTNER_ID, options: .literal, range: nil)
        }
    }
    
    
  
    
 
}
