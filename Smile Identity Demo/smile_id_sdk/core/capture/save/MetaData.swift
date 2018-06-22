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
class MetaData {
    
    static let KEY_PACKAGE_INFORMATION      :
        String = "package_information"
    static let KEY_MISC_INFORMATION         :
        String = "misc_information"
    static let KEY_SERVER_INFO              :
        String = "server_information"
    static let KEY_USER_ID_INFORMATION      :
        String = "id_info"

    var packageInfo                         : PackageInfo?
    
    // lambda request goes into the misc info block
    var miscInfo                            : MiscInfo?
    
    // lambda Response goes into the serverInfo block
    var serverInfo                          : String?
    
    var sidUserIdInfo                       : SIDUserIdInfo?
    
    init( packageInfo       : PackageInfo,
          miscInfo          : MiscInfo,
          serverInfo        : String,
          sidUserIdInfo     : SIDUserIdInfo
        ){
        self.packageInfo = packageInfo
        self.miscInfo = miscInfo
        self.serverInfo = serverInfo
        self.sidUserIdInfo = sidUserIdInfo
    }
    
    func fromJsonString( jsonString : String ) -> MetaData? {
        if( jsonString.isEmpty ){
            return nil
        }
        else{
            let jsonUtils = JsonUtils()
            let dict = jsonUtils.jsonFormattedStringToDict( jsonString )

            let packageInfoDict = jsonUtils.getDict(dict: dict!,
                key: MetaData.KEY_PACKAGE_INFORMATION,
                defaultVal:  [String:Any]() )
            packageInfo = PackageInfo().fromJsonDict(dict: packageInfoDict)
            
            let miscInfoDict = jsonUtils.getDict(dict: dict!, key: MetaData.KEY_MISC_INFORMATION,
                defaultVal:  [String:Any]() )
            miscInfo = MiscInfo().fromJsonDict(dict: miscInfoDict)
            
            serverInfo = jsonUtils.getString(dict: dict!,
                key: MetaData.KEY_SERVER_INFO,
                defaultVal : "" )
            
            let sidUserIdInfoDict = jsonUtils.getDict(dict: dict!,
                key: MetaData.KEY_USER_ID_INFORMATION,
                defaultVal:  [String:Any]() )
                
            sidUserIdInfo = SIDUserIdInfo().fromJsonDict(dict: sidUserIdInfoDict)
            
            return self
            
        }
    }
  
    
    func toJsonDict() -> Dictionary<String,Any> {
        // Build a dictionary,
        var dict = [String: Any]()
        
        let jsonUtils = JsonUtils()
        
        jsonUtils.putDict( dict: &dict, key: MetaData.KEY_PACKAGE_INFORMATION,
            val: ( packageInfo!.toJsonDict()) )
        
        jsonUtils.putDict( dict: &dict, key: MetaData.KEY_MISC_INFORMATION,
                           val: ( miscInfo!.toJsonDict()) )
        
        jsonUtils.putString( dict: &dict, key: MetaData.KEY_SERVER_INFO,
                             val: serverInfo! )
        
        jsonUtils.putDict( dict: &dict, key: MetaData.KEY_USER_ID_INFORMATION,
                           val: sidUserIdInfo!.toJsonDict(useAdditionalProps: false) )
        
        return dict
    }
    
    func toJsonString() -> String {
        let jsonUtils = JsonUtils()
        return jsonUtils.dictToJsonFormattedString( dict : toJsonDict() )
    }
    
    
 
    
    
}
