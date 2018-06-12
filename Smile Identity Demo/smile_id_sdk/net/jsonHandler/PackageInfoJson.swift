//
//  PackageInfoJson.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/30/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation


/*
 PackageInfoJson - builds the top level json for the entire info.json file.
 
 Note that the "package_information" block is built by the MetaData class
 */
class PackageInfoJson {
    
    static let KEY_PACKAGE_INFORMATION      :
        String = "package_information"
    static let KEY_SERVER_INFO              :
        String = "server_information"
    static let KEY_MISC_INFORMATION         :
        String = "misc_information"
    static let KEY_ID_INFORMATION         :
        String = "id_info"

    
    var lambdaResponse                      : UploadDataResponse?
    
    // Android code is using the sidMetaData as singleton.
    // Here, we are passing it in.
    var sidMetaData                         : SIDMetadata?
    
    var jsDictPackageInformation                = [String : String] ()
    var jsDictMisc                              = [String : String] ()
    
    let jsonUtils                           = JsonUtils()
    
    init(  lambdaResponse : UploadDataResponse,
           jsDictPackageInformation : [String : String],
           jsDictMisc : [String : String],
           sidMetaData : SIDMetadata
           ) {
        self.lambdaResponse = lambdaResponse
        self.jsDictPackageInformation = jsDictPackageInformation
        self.jsDictMisc = jsDictMisc
        self.sidMetaData = sidMetaData

    }
    
    
    func toJsonDict() -> Dictionary<String,Any> {
        // Build a dictionary,
        var dict = [String: Any]()
        
        let jsonUtils = JsonUtils()
        
        jsonUtils.putDict( dict: &dict, key: PackageInfoJson.KEY_PACKAGE_INFORMATION,
            val: jsDictPackageInformation )
        
        jsonUtils.putDict( dict: &dict, key: PackageInfoJson.KEY_MISC_INFORMATION,
                           val: jsDictMisc )
        
        jsonUtils.putString( dict: &dict, key: PackageInfoJson.KEY_SERVER_INFO,
                             val: (lambdaResponse?.rawJsonString)! )
        
        jsonUtils.putDict( dict: &dict, key: PackageInfoJson.KEY_ID_INFORMATION,
                           val: (sidMetaData?.sidUserIdInfo.toJsonDict(useAdditionalProps: false))! )
        
        return dict
    }
    
    func toJsonString() -> String {
  
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )

    }

    
}
