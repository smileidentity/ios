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
    
    init() {
        let appData = AppData()
        referenceId = appData.getRefID(defaultRefID: SIDReferenceId.DEFAULT_REFERENCE_ID);
        
    }
    
    
    func deleteMetaFolder( referenceId : String ) {
        let appData = AppData()
        appData.removeTag(tag: referenceId)
        
        let siFileManager = SIFileFileManager()
        siFileManager.deleteMetaFolder(referenceId: referenceId)
    }
    
    
    func clearMetadata()  {
        SmileIDSingleton.sharedInstance.idCardFrame = nil
        let appData = AppData()
        appData.clearJobResponse()
        appData.removeCurrentTag();
        appData.setIsIDPresent(isIDPresent: false)
    }
    
    

    
    
    
}
