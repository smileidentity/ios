//
//  Test.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class Test {

    func test() {
        
        /*
        let authSmileResponse = AuthSmileResponse()
        var jsonFormattedString = "{"
        jsonFormattedString += "\"success\": true,"
        jsonFormattedString += "\"errors\": [\"err1\", \"err2\"],"
        jsonFormattedString += "\"user_errors\": [\"usererr1\", \"usererr2\"],"
        jsonFormattedString += "\"timestamp\": 5,"
        jsonFormattedString += "\"sec_key\": \"mySecKey\","
        jsonFormattedString += "\"smile_client_id\": \"my client id\","
        jsonFormattedString += "\"callback_url\": \"http://whatever.com\","
        jsonFormattedString += "\"partner_params\": {"
        jsonFormattedString += "\"user_id\": \"ppUserIdv\","
        jsonFormattedString += "\"job_id\": \"vppJobId\","
        jsonFormattedString += "\"job_type\": 1"
        jsonFormattedString += "}"
        jsonFormattedString +=  "}"
        
        authSmileResponse.fromJsonString(jsonFormattedString:  jsonFormattedString )
 
         */
        /*
        var partnerParams = PartnerParams ( userId : "myUserId", jobId: "myjobId", jobType: 5 )
        partnerParams.additionalValues["1"] = "add 1"
        partnerParams.toJsonString()
        */
        
        /*
        print( "Test error message : ", SIDError.getErrorMessage(errorCode:  SIDError.COULD_NOT_INITIALIZE_CAMERA ))
        */
        
        let siFileFileManager = SIFileFileManager()
        siFileFileManager.deletePreviewFrames(referenceID: "000000")
        
    }
    
  
    
    
  
    
}
