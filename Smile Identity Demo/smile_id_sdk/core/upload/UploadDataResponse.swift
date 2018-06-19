//
//  UploadDataResponse.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class UploadDataResponse {
    
    static let KEY_UPLOAD_URL           : String    = "upload_url"
    static let KEY_SMILE_JOB_ID         : String    = "smile_job_id"
    static let KEY_REF_ID               : String    = "ref_id"
    
    var uploadUrl   : String    = ""
    var smileJobId : String     = ""
    // private CameraConfig cameraConfig; unused
    var refId       : String    = ""
    var additionalProperties        = [String : String] ()
    let jsonUtils       = JsonUtils()
    
    var rawJsonString   : String = "";
    
    func getRawJsonString() -> String { return rawJsonString }

    
    /* Initialize from json string */
    func fromJsonString( jsonFormattedString : String ) -> UploadDataResponse? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            rawJsonString = jsonFormattedString
            let dict = jsonUtils.jsonFormattedStringToDict( jsonFormattedString )
            
            uploadUrl = jsonUtils.getString(dict: dict!,
                        key: UploadDataResponse.KEY_UPLOAD_URL,
                        defaultVal: "" )

            smileJobId = jsonUtils.getString(dict: dict!,
                key: UploadDataResponse.KEY_SMILE_JOB_ID,
                defaultVal: "" )
            
            refId = jsonUtils.getString(dict: dict!, key: UploadDataResponse.KEY_REF_ID,
                defaultVal: "" )
            
        }
        
        return self
    }
    
 
    
 
    
}
