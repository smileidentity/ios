//
//  SIDNetworkRequest.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDNetworkRequest {
    
    var delegate    : SIDNetworkRequestDelegate?
    
    func setDelegate( delegate : SIDNetworkRequestDelegate){
        self.delegate = delegate
    }
    
    func initialize() {
        // In Android code, this function initializes the
        // broadcast receivers for the upload
    }
    
   
    

}
