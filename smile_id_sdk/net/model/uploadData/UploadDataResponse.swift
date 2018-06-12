//
//  UploadDataResponse.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class UploadDataResponse : JsonResponse {
    
    static let KEY_UPLOAD_URL           : String    = "upload_url"
    static let KEY_SMILE_JOB_ID         : String    = "smile_job_id"
    static let KEY_REF_ID               : String    = "ref_id"
    
    var uploadUrl   : String?
    var smileJobId : String?
    // private CameraConfig cameraConfig; unused
    var refId       : String?
    var additionalProperties        = [String : String] ()
    let jsonUtils       = JsonUtils()
    
    /* Initialize from json string */
    override func fromJsonString( jsonFormattedString : String ) -> UploadDataResponse? {
        if( jsonFormattedString.isEmpty ){
            return nil
        }
        else{
            rawJsonString = jsonFormattedString
            let dict = jsonUtils.jsonFormattedStringToDict( jsonFormattedString )
            setUploadDataResponse(dict: dict!)
        }
        
        return self
    }
    
    func setUploadDataResponse( dict : [String : Any] ){
        uploadUrl = jsonUtils.getString(dict: dict, key: UploadDataResponse.KEY_UPLOAD_URL )
        smileJobId = jsonUtils.getString(dict: dict, key: UploadDataResponse.KEY_SMILE_JOB_ID )
        refId = jsonUtils.getString(dict: dict, key: UploadDataResponse.KEY_REF_ID )
        
    }
    
 
    
}
