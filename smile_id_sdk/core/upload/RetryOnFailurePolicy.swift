//
//  RetryOnFailurePolicy.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/8/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class RetryOnFailurePolicy {
    
    let MAX_RETRIES         : Int = 50
    
    var maxRetryCount       : Int = 2
     /* 5 seconds */
    var maxRetryTimeoutSec  : Int = 5
 
    func getMaxRetryCount() -> Int {
        
        if( maxRetryCount > MAX_RETRIES ){
            return MAX_RETRIES
        }
        else{
            return maxRetryCount
        }
    }
    
}
