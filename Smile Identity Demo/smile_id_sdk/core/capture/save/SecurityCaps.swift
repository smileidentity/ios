//
//  SecurityCaps.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SecurityCaps {
    static let KEY_AES_CAPABLE       : String = "AESCapable"
    static let KEY_RSA_CAPABLE       : String = "RSACapable"
    
    
    let AESCapable : Bool = false;
    let RSACapable : Bool = false;
    
    
    func toJsonDict() -> Dictionary<String,Any> {
        
        let jsonUtils = JsonUtils()
        var dict = [String: Any]()
        
        jsonUtils.putBool( dict: &dict, key: SecurityCaps.KEY_AES_CAPABLE,
                          val: AESCapable )
        
        jsonUtils.putBool( dict: &dict, key: SecurityCaps.KEY_RSA_CAPABLE,
                           val: RSACapable )
     
        return dict
    }
    
    
}
