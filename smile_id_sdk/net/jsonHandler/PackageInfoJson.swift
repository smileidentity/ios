//
//  PackageInfoJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/30/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class PackageInfoJson {
    
    static let KEY_SERVER_INFO              :
        String = "server_information"
    static let KEY_PACKAGE_INFORMATION      :
        String = "package_information"
    static let KEY_MISC_INFORMATION         :
        String = "misc_information"

    
    var lambdaResponse                      : UploadDataResponse?
    
    // Android code is using the sidMetaData as singleton.
    // Here, we are passing it in.
    var sidMetaData                         : SIDMetadata?
    
    var jsPackageInformation                = [String : String] ()
    var jsMisc                              = [String : String] ()
    
    let jsonUtils                           = JsonUtils()
    
    init(  lambdaResponse : UploadDataResponse,
           jsPackageInformation : [String : String],
           jsMisc : [String : String],
           sidMetaData : SIDMetadata
           ) {
        self.lambdaResponse = lambdaResponse
        self.jsPackageInformation = jsPackageInformation
        self.jsMisc = jsMisc
        self.sidMetaData = sidMetaData

    }
    
    func toJsonString() -> String {
        // Build a dictionary,
        // then convert it to a formatted json string
        var dict = [String: Any]()
         
        dict[PackageInfoJson.KEY_PACKAGE_INFORMATION] = jsPackageInformation
        dict[PackageInfoJson.KEY_MISC_INFORMATION] = jsMisc
        dict[PackageInfoJson.KEY_SERVER_INFO] = lambdaResponse!.getRawJsonString()
        
        let jsSidUserIdInfo = sidMetaData?.sidUserIdInfo?.toJsonString()
        let sidUserInfoDict = jsonUtils.jsonFormattedStringToDict( jsSidUserIdInfo! )
      
        dict[SIDUserIdInfo.SECTION_NAME] = sidUserInfoDict
       
        return jsonUtils.dictToJsonFormattedString( dict : dict )

    }

    
}
