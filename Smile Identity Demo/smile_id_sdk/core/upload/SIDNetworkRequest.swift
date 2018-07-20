//
//  SIDNetworkRequest.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SIDNetworkRequest : PackageServiceDelegate,
UploadServiceDelegate {
 
    
    static let ONE_MIN_MS           : Int64 = 60 * 1000       // 1 minutes in ms
    static let MAX_RETRY_TIME_MS    : Int64 = ONE_MIN_MS * 15 // 15 minutes in ms
    static let DEFAULT_DELAY        : Double = 0.1            // 100 MS
    
    
    static let PARTNER_ID           : String = "003";

    /* Default value of optionals is nil */
    
    var delegate                : SIDNetworkRequestDelegate?
    var tag                     : String?
    var retryOnFailurePolicy    = RetryOnFailurePolicy()
    var partnerParams           : PartnerParams?
    var jobType                 : Int = -1
    var currentRetryCount       : Int?
    var sidNetData              : SIDNetData?
    var isEnrollMode            : Bool = false
    var hasId                   : Bool = false
    
    var startTimeMS             : Int64?
    var requiredPassedTimeMS    : Int64 = 60 * 1000 // 1 minute in milliseconds
   
    var geoInfos                : GeoInfos?
    var requestNewToken         : Bool = false
    var retry                   : Bool = false
    var uploadService           : UploadService?
    
    var referenceId             : String?
    
    func setDelegate( delegate : SIDNetworkRequestDelegate){
        self.delegate = delegate
        
    }
    
    func initialize() {
        self.geoInfos = SmileIDSingleton.sharedInstance.geoInfos
    }
    
    
    func userCancelled() {
        // Android code treats user cancelled logic different
        // than cancelRetries. cancelRetries is for cancelling the upload retries.
        // So, iOS will do the same - if user cancels we do not call cancelRetries.
        // cancelRetries()
        if( uploadService != nil ){
            uploadService!.cancel()
        }
    }
    
    func submit( sidConfig : SIDConfig ) throws {

        let appData = AppData()
        
        
        referenceId = appData.createReferenceId(tag: SmileIDSingleton.USER_TAG )
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
        
  
        currentRetryCount = retryOnFailurePolicy.getMaxRetryCount()
        sidNetData = sidConfig.sidNetData
        isEnrollMode = sidConfig.isEnrollMode
        hasId = sidConfig.useIdCard
        startTimeMS = Int64(NSDate().timeIntervalSince1970 * 1000)
        
        appData.clearJobResponse()
        
        /* appData set/get Current job type is not used in the Android code.
         It is set but never read.
         
         
         Note that the AppData method setCurrentJobType does not
         use the jobType as it is set in sidConfig.
         
         if( isEnrollMode )!{
         appData.setCurrentJobType(currentJobType: 1)
         }
         else{
         appData.setCurrentJobType(currentJobType: 0)
         }
         */
        
        setUserData( partnerParams: partnerParams, isEnrollMode: isEnrollMode )
        
        
        // This will start the process of packaging and uploading.
        doSubmit( delay: SIDNetworkRequest.DEFAULT_DELAY )
    }

    
    func doSubmit( delay : Double ) {
        
        if( currentRetryCount! < 0 ){
            return
        }
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Start the package service.
            // When the PackageService is done, the onPackagingComplete callback
            // is called.   onPackagingComplete starts the UploadService
            
  
            self.startPackageService( packageService:       PackageService(referenceId:self.referenceId!),
                  sidNetData: self.sidNetData!,
                  isEnrollMode : self.isEnrollMode )
        }
        currentRetryCount = currentRetryCount! - 1
  
    }
    
    
    
    func startPackageService(   packageService : PackageService,
                                sidNetData : SIDNetData,
                                isEnrollMode : Bool ){
        
        let authUrl = sidNetData.insertPartnerId(urlString: sidNetData.authUrl)
        sidNetData.authUrl = authUrl
        let jobStatusUrl = sidNetData.insertPartnerId(urlString: sidNetData.jobStatusUrl)
        sidNetData.jobStatusUrl = jobStatusUrl
        checkAndUpdateRetryFlag();
        let coreRequest = createCoreRequestData(sidNetData: sidNetData,
                                                isEnrollMode: isEnrollMode )
        packageService.packAndSend(coreRequestData: coreRequest,
                                   packageServiceDelegate: self )
    }
    
    
    func checkTagExists( tag : String ) -> Bool {
        
        let appData = AppData()
        let tags = appData.getTags()
        if( tags == nil ){
            delegate?.onError( sidError: SIDError.TAG_NOT_FOUND )
            return false
        }
        let containsTag = tags!.contains(tag)
        if( !containsTag ){
            delegate?.onError( sidError: SIDError.TAG_NOT_FOUND )
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

            let appData = AppData()
            referenceId = appData.createReferenceId(tag: SmileIDSingleton.USER_TAG )
            
            let packageService = PackageService( referenceId: referenceId! )
            try packageService.saveCapturedData(tag: tag, sidNetData: smileIdNetData)
        }
        catch let sidError as SIDError {
             delegate?.onError(sidError: sidError )
        }
        catch {
            let logger = SILog()
            logger.SIPrint(logOutput: "An error occurred while saving data for later use")
        }
        
    }
    
    
    /*
     This is an Android port - retry flag does not appear to be used accept to
     pass through to the lambda request.   It is hardcoded to false when it is
     passed back in onUploadServiceComplete.
    */
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
 
    
    
 
    
    /*
        PackageServiceDelegate callbacks
    */
    func onPackagingComplete( packageInfo : PackageInfo,
                              coreRequestData : CoreRequestData ){
        uploadService = UploadService(uploadServiceDelegate: self, referenceId: referenceId!)
        uploadService!.start(coreRequestData: coreRequestData, packageInfo: packageInfo);
        
    }
    
    func onPackagingError( sidError : SIDError ){
        DispatchQueue.main.async {
            self.delegate!.onError(sidError: sidError )
        }
    }
    
    /*
     UploadServiceDelegate callbacks.
     
     The submit logic is done in the background,
     so any callbacks to the ui delegate should be done in the foreground.
     That is way the callbacks are wrapped in DispatchQueue.main.async
     */
    
    func onStartJobStatus(){
        DispatchQueue.main.async {
            self.delegate!.onStartJobStatus()
        }
    }
    func onEndJobStatus() {
        DispatchQueue.main.async {
            self.delegate!.onEndJobStatus()
        }
    }
    
 
    func onUpdateJobStatus(msg: String) {
        DispatchQueue.main.async {
            self.delegate!.onUpdateJobStatus( msg: msg )
        }
    }
    
    func onUpdateJobProgress(progress: Int) {
        DispatchQueue.main.async {
            self.delegate!.onUpdateJobProgress( progress: progress )
        }
    }
    
    

    
    
    func onUploadServiceComplete(sidError: SIDError,
                                 confidenceValue: Float,
                                 retryFlag: Bool,
                                 partnerParams: PartnerParams?) {
        DispatchQueue.main.async {
            self.delegate?.onComplete()
        }
        
        let success = isSuccess( sidError: sidError )
        retry = retryFlag
  
        
        let sidResponse = SIDResponse( partnerParams:partnerParams,
                                       success: success,
                                       confidenceValue: confidenceValue )
        
        if( success ){
            if( isEnrollMode ){
                DispatchQueue.main.async {
                    self.delegate?.onEnrolled(sidResponse: sidResponse )
                }
            }
            else{
                DispatchQueue.main.async {
                    self.delegate?.onAuthenticated(sidResponse: sidResponse )
                }
            }
            
            cancelRetries();
            
        }
        else{
            if( isEnrollMode ){
                DispatchQueue.main.async {
                    self.delegate?.onEnrolled(sidResponse: sidResponse )
                }
            }
  
                
            DispatchQueue.main.async {
                self.delegate?.onError( sidError: sidError )
            }
            
            if( unableToVerify(sidError: sidError ) ){
                DispatchQueue.main.async {
                    self.delegate?.onAuthenticated(sidResponse: sidResponse )
                }
                cancelRetries()
            }
            else{
                // cancel the uploadjobstatus
                uploadService!.cancel()
            
                doSubmit( delay: Double( retryOnFailurePolicy.maxRetryTimeoutSec) )
            }
            
        }
 

    }
    
      
  
    
    func cancelRetries() {
        // cancel retries
    }
    
    
    
    func isSuccess( sidError : SIDError ) -> Bool {
        switch( sidError ){
        case SIDError.SUCCESS :
            return true
        default :
            return false
        } // switch
    }
    func unableToVerify( sidError : SIDError ) -> Bool {
        switch( sidError ){
        case SIDError.UNABLE_TO_VERIFY :
            return true
        default :
            return false
        } // switch
    }
    
  


    

}
