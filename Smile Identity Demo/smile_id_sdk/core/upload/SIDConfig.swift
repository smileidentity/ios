//
//  SIDConfig.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

public class SIDConfig {
    var retryOnFailurePolicy    : RetryOnFailurePolicy?
    var sidNetData              : SIDNetData?
    var isEnrollMode            : Bool = false
    var tag                     = SIDReferenceId.NO_TAG
 
    var sidNetworkRequest       = SIDNetworkRequest()
    var useIdCard               : Bool = false
  
    var jobType                 : Int = -1
    
    func setRefId( tag : String ) {
        let appData = AppData()
        appData.setRefID(refID: appData.createReferenceId(tag: tag));
    }
    
    func save() {
        let appData = AppData()
        appData.setTag(tag: tag);
        
        /* TODO - implment this function
        sidNetworkRequest.saveDataForLaterUse(tag, sidNetData);
         */
    }
    
    func updateIDPresent() {
        let appData = AppData()
        appData.setIsIDPresent(isIDPresent: useIdCard);
    }
    
    func build( tag : String ) {
        let appData = AppData()
        appData.setIsIDPresent(isIDPresent: useIdCard)
        self.tag = tag;
        setRefId(tag: tag);
        save();
    }

}
