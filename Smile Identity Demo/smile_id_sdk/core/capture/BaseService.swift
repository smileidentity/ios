//
//  BaseService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class BaseService {
    
    var referenceId : String?
    
    init() {}
    
    
    func deleteMetaFolder( referenceId : String ) {
        let appData = AppData()
        appData.removeTag(tag: referenceId)
        
        let siFileManager = SIFileManager()
        siFileManager.deleteMetaFolder(referenceId: referenceId)
    }
    
    
    func clearMetadata()  {
        let appData = AppData()
        appData.clearJobResponse()
        appData.removeCurrentTag();
        appData.setIsIDPresent(isIDPresent: false)
    }
    
    
    
    
    func readMetadata() -> String? {
        var jsMetaData : String?
        
        let siFileManager = SIFileManager()
        let metaFileURL = siFileManager.getMetaFilePathAsURL(referenceId:  referenceId! )
        do {
            if( siFileManager.fileExists(fullFilePath: metaFileURL.path) ){
                jsMetaData = try String(contentsOf: metaFileURL, encoding: .utf8)
            }
        }
        catch {
            let logger = SILog()
            logger.SIPrint(logOutput: "An error occurred reading the metafile.")
        }
        
        return jsMetaData
    }
    
    
    func writeMetaData( metaData : MetaData ) {
        let siFileManager = SIFileManager()
        let metaFileURL = siFileManager.getMetaFilePathAsURL(referenceId:  referenceId! )
        do {
            let jsMetaData = metaData.toJsonString()
            try jsMetaData.write(to: metaFileURL, atomically: false, encoding: .utf8)
        }
        catch {
            let logger = SILog()
            logger.SIPrint(logOutput: "An error occurred writing the metafile.")
        }
        
    }
    
    
    

    
    
    
}
