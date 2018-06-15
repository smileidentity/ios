//
//  SIDNetworkRequest.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDNetworkRequest {
    
    /* Default value of optionals is nil */
    
    var delegate                : SIDNetworkRequestDelegate?
    var tag                     : String?
    var retryOnFailurePolicy    = RetryOnFailurePolicy()
    var partnerParams           : PartnerParams?
    var jobType                 : Int = -1
    var currentRetryCount       : Int?
    var sidNetData              : SIDNetData?
    var isEnrollMode            : Bool = false
    var startTimeMS             : Int64?
    
    var geoInfos                : GeoInfos = GeoInfos()
    var jsGeoInfos              : String?
    
    func setDelegate( delegate : SIDNetworkRequestDelegate){
        self.delegate = delegate
    }
    
    func initialize() {}
    
    func submit( sidConfig : SIDConfig ) throws {
        if( sidConfig.sidNetData == nil ){
            throw SIDError.NETWORK_DATA_NOT_VALID
        }
        
        tag = sidConfig.tag
        if( sidConfig.retryOnFailurePolicy != nil ){
            retryOnFailurePolicy = sidConfig.retryOnFailurePolicy!
        }
        
        partnerParams = PartnerParams()
        jobType = sidConfig.jobType
        
        coreSubmit( sidConfig: sidConfig )
        
    }
    
    func coreSubmit( sidConfig : SIDConfig ) {
        currentRetryCount = retryOnFailurePolicy.getMaxRetryCount()
        sidNetData = sidConfig.sidNetData
        isEnrollMode = sidConfig.isEnrollMode
        startTimeMS = Int64(NSDate().timeIntervalSince1970 * 1000)
        let appData = AppData()
        appData.clearJobResponse()
        
        /* appData set/get Current job type is not used in the Android code.
         It is set but never read.
      
        
        Note that the AppData method setCurrentJobType does not use the jobType as it is set
            in sidConfig.
 
        if( isEnrollMode )!{
            appData.setCurrentJobType(currentJobType: 1)
        }
        else{
            appData.setCurrentJobType(currentJobType: 0)
        }
        */
        
        setUserData( partnerParams: partnerParams, isEnrollMode: isEnrollMode )
        jsGeoInfos = geoInfos.toJsonString()
        
        
        
        
        
    }
    
    
    
    
    func setUserData( partnerParams : PartnerParams?,
                      isEnrollMode  : Bool ) {
        let appData = AppData()
        if( isEnrollMode ){
            appData.removeUserId()
            appData.removeLastEnrolledJobId()
        }
        else{
            // auth mode
            if( partnerParams != nil ){
                let userId = partnerParams?.userId
                let jobId = partnerParams?.jobId
                if( (!userId!.isEmpty) &&
                    (!jobId!.isEmpty) ){
                    appData.setUserId(userId: userId!)
                    appData.setJobId(jobId: jobId!)
                }
            }
        }
        
   
    
    }

    
    
    
    

}
