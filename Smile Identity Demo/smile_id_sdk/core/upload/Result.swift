//
//  Result.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

/* Note that Android has two Result classes, both identical.  One under status package, and the other under uploadData */
class Result {
    var resultText              : String = "";
    var resultType              : String = "";
    var smileJobID              : String = "";
    var jSONVersion             : String = "";
    var isFinalResult           : String = "";
    var partnerParams           = PartnerParams();
    var confidenceValue         : String = "0";
    var isMachineResult         : String = "";
    var additionalProperties    = [String : String] ()
    
    func getIsFinalResult() -> Bool {
        if( isFinalResult == "true" ){
            return true
        }
        else {
            return false
        }
    }
    
    func getConfidenceValue() -> Double {
        
        if( confidenceValue.isEmpty ){
            return 0.0
        }
        
        let dRetVal = Double(confidenceValue)
        if( dRetVal != nil ){
            return dRetVal!
        }
        else{
            return 0.0
        }
        
  
    }


    
}
