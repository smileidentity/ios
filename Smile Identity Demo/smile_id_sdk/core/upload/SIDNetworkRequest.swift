//
//  SIDNetworkRequest.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDNetworkRequest {
    
    static let ONE_MIN_MS           : Int64 = 60 * 1000       // 1 minutes in ms
    static let MAX_RETRY_TIME_MS    : Int64 = ONE_MIN_MS * 15 // 15 minutes in ms
    static let PARTNER_ID           : String = "023";
    
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
    var requiredPassedTimeMS    : Int64 = 60 * 1000 // 1 minute in milliseconds
   
    var geoInfos                : GeoInfos = GeoInfos()
    var requestNewToken         : Bool = false
    var retry                   : Bool = false
    
    func setDelegate( delegate : SIDNetworkRequestDelegate){
        self.delegate = delegate
    }
    
    func initialize() {}
    
    func submit( sidConfig : SIDConfig ) throws {
        if( sidConfig.sidNetData == nil ){
            throw SIDError.NETWORK_DATA_NOT_VALID
        }
        
        tag = sidConfig.tag
        if( !checkTagExists(tag: tag! )){
            return
        }
        
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
        
    }
    
    
    
    func startPackageService(   packageService : PackageService,
                                sidNetData : SIDNetData,
                                isEnrollMode : Bool ){
        
        let authUrl = sidNetData.insertPartnerId(partnerId: SIDNetworkRequest.PARTNER_ID)
        sidNetData.authUrl = authUrl
        checkAndUpdateRetryFlag();
        let coreRequest = createCoreRequestData(sidNetData: sidNetData,
                                                isEnrollMode: isEnrollMode )
        packageService.packAndSend(coreRequestData: coreRequest)
    }
    
    
    func checkTagExists( tag : String ) -> Bool {
        
        let appData = AppData()
        let tags = appData.getTags()
        if( !tags.contains(tag)){
            
            // TODO : wire this
            // onError( SIDError.TAG_NOT_FOUND )
            return false
        }
        else{
            return true
        }

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

    
    // called from SIDConfig build -> save logic.
    func saveDataForLaterUse( tag : String, smileIdNetData : SIDNetData ) {
        do {
            let packageService = PackageService()
            try packageService.saveCapturedData(tag: tag, sidNetData: smileIdNetData)
        }
        catch let error as SIDError {
            // TODO wire this onError( error )
        }
        catch {
            // TODO wire this onError( error )
        }
        
    }
    
    
    func checkAndUpdateRetryFlag() {
        requestNewToken = false;
        
        let nowMS = Int64(NSDate().timeIntervalSince1970 * 1000)
        let deltaTimeMS = nowMS - startTimeMS!
        if( ( deltaTimeMS > requiredPassedTimeMS ) &&
            ( deltaTimeMS <= SIDNetworkRequest.MAX_RETRY_TIME_MS ) ) {
            retry = true
        }
        else {
            retry = false
        }
        
        if( deltaTimeMS > SIDNetworkRequest.MAX_RETRY_TIME_MS ){
            startTimeMS = Int64(NSDate().timeIntervalSince1970 * 1000)
            requestNewToken = true
        }
    }
    
 
    
    func createCoreRequestData( sidNetData : SIDNetData,
                                isEnrollMode : Bool ) -> CoreRequestData {
        let coreRequestData = CoreRequestData()
        coreRequestData.sidNetData = sidNetData
        coreRequestData.geoInfos = geoInfos
        coreRequestData.partnerParams = partnerParams
        coreRequestData.tag = tag
        coreRequestData.requestNewToken = requestNewToken
        coreRequestData.retry = retry
        coreRequestData.jobType = jobType
        coreRequestData.isEnrollMode = isEnrollMode
        return coreRequestData;
    }
    
    
    // Listeners
    
    func onUploadFinished(  isSuccess       : Bool,
                            confidenceValue : Float,
                            partnerParams   : PartnerParams,
                            retry           : Bool,
                            sidError        : SIDError ){
        
        self.partnerParams = partnerParams
        self.retry = retry
 
        // TODO wire this
        delegate!.onComplete()
        
        let sidResponse = SIDResponse()
        sidResponse.partnerParams = partnerParams
        sidResponse.success = isSuccess
        sidResponse.confidenceValue = confidenceValue
        if( isSuccess ){
            sidResponse.success = true
            if( isEnrollMode ){
                delegate!.onEnrolled(response: sidResponse )
            }
            else{
                delegate!.onAuthenticated(response: sidResponse)
            }
            
            // TODO cancel thread
        }
        else {
            if( isEnrollMode ){
                delegate!.onEnrolled(response: sidResponse )
            }
            
            // TODO wire this
            delegate!.onError(errMsg: sidError.message)
            
            if( isUnableToVerifyError( sidError: sidError ) &&
                !isEnrollMode ) {
                delegate!.onAuthenticated(response: sidResponse)
            }
            else{
                // TODO wire retry
            }
            
        }
    }
    
    
    func isUnableToVerifyError( sidError : SIDError ) -> Bool {
        
        switch sidError {
            case SIDError.UNABLE_TO_VERIFY:
                return true
            default :
                return false
        }
    }
    
 
    

}
