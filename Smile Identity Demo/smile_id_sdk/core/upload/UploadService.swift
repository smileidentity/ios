//
//  UploadService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/13/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class UploadService : BaseService, NetRequestDelegate {

    var netRequest  : NetRequest?
    var isCancelled : Bool = false

    var uploadServiceDelegate                   : UploadServiceDelegate?
    var confidenceValue                         : Float = 0.0
    var jobComplete                             : Bool = false
    var sidNetData                              : SIDNetData?
    var partnerParams                           : PartnerParams?
    var requestNewToken                         : Bool?
    var retry                                   : Bool?
    var isEnrollMode                            : Bool?
    var jobType                                 : Int?
    var geoInfos                                : GeoInfos?
    var authSmileResponse                       : AuthSmileResponse?
    var lambdaRequest                           : LambdaRequest?
    var packageInfo                             : PackageInfo?
    
    
    init( uploadServiceDelegate : UploadServiceDelegate,
          referenceId : String ){
        super.init()
        super.referenceId = referenceId
        self.uploadServiceDelegate = uploadServiceDelegate
    }
    
    func cancel() {
        isCancelled = true
        netRequest?.cancel()
    }

    func start( coreRequestData     : CoreRequestData,
                packageInfo         : PackageInfo ){
        
            self.packageInfo = packageInfo

            sidNetData = coreRequestData.sidNetData
            partnerParams = coreRequestData.partnerParams
            requestNewToken = coreRequestData.requestNewToken
            retry = coreRequestData.retry
            isEnrollMode = coreRequestData.isEnrollMode
            jobType = coreRequestData.jobType
            geoInfos = coreRequestData.geoInfos
            
            netRequest = NetRequest(netRequestDelegate: self)
            isCancelled = false
            
            // Start the process with step 1, post auth smile
            postAuthSmile()
 
    }
    
    
    /*
     Step 1
     Get an post AuthSmile, if necessary.
    */
    func postAuthSmile() {
        uploadServiceDelegate?.onStartJobStatus()
        
        let appData = AppData()
        let sAuthResponse = appData.getAuthSmileResponse(defaultVal: nil )
        
        if( sAuthResponse != nil ){
            authSmileResponse = AuthSmileResponse().fromJsonString( jsonFormattedString: sAuthResponse! )
        }
        
        if( requestNewToken! || authSmileResponse == nil ){
            /* Get a new authSmileResponse */
            netRequest?.postAuthSmile(
                partnerUrl: sidNetData!.partnerUrl,
                authUrl: sidNetData!.authUrl,
                jobStatusUrl: sidNetData!.jobStatusUrl,
                jobType: jobType!,
                isEnrollMode: isEnrollMode! )
            
            appData.setAuthSmileResponse(response: authSmileResponse);
        }
        else{
            // Skip to step 2
            onPostAuthSmileComplete( authSmileResponse: authSmileResponse! )
        }
    }
    
    /* postAuthSmile callback from NetRequest */
    /* Could use a completion handler just as well as a delegate for these callbacks,
        but for consistancy, will use delegates.
        This is because the netRequest uploadJobStatus function uses a delegate, because it is
        using a timer, so can't return objects in a completion handler
    */

    func onPostAuthSmileComplete( authSmileResponse : AuthSmileResponse? ){
        uploadServiceDelegate?.onEndJobStatus()
        if( authSmileResponse != nil && !isCancelled ){
            // Go to step 2
            postLambda( authSmileResponse: authSmileResponse! )
        }
        else{
            if( !jobComplete ) {
                // Note that in Android code, jobComplete is never set to true
                let appData = AppData()
                appData.removeJobResponse();
                
                if( isEnrollMode )! {
                   onError( sidError: SIDError.UNABLE_TO_SUBMIT_COULD_NOT_AUTH )
                }
                else {
                   onError( sidError: SIDError.FAILED_JOB_STATUS_CANCELLED_OR_TIMEOUT_AUTH)
                }
            }
        }
    }
    
    
    /* Step 2 post Lambda */
    func postLambda( authSmileResponse : AuthSmileResponse ) {
        
        let appData = AppData()
        appData.setAuthSmileResponse(response: authSmileResponse)
        
        let jsLambdaRequest = buildLambdaRequest(
            phoneNumber: getPhoneNumber(), // Apple does not support this
            referenceId: referenceId!,
            deviceId: UIDevice.current.identifierForVendor!.uuidString,
            authResponse: authSmileResponse,
            partnerParams: partnerParams!,
            retry: retry!,
            isEnrollMode: isEnrollMode!)
        
        netRequest!.postLambda(jsLambdaRequest: jsLambdaRequest,
                              lambdaUrl : sidNetData!.lambdaUrl )
            
            
        
    }
    
    
    func buildLambdaRequest( phoneNumber : String,
                             referenceId : String,
                             deviceId : String,
                             authResponse : AuthSmileResponse,
                             partnerParams : PartnerParams,
                             retry : Bool,
                             isEnrollMode : Bool ) -> String {
        
        let appData = AppData()
        let jobId = authResponse.partnerParams.jobId
        let smileClientId = authResponse.smileClientId!
        appData.setSmileClientId(smileClientId:smileClientId )
        
        if( isEnrollMode ){
            appData.setUserId( userId: authResponse.partnerParams.userId )
            appData.setLastEnrollJobId(lastEnrollJobId: jobId )
        }
        else {
            appData.setJobId(jobId: jobId )
        }
        
        lambdaRequest = LambdaRequest(
            phoneNumber: phoneNumber,
            referenceId: referenceId,
            deviceId: deviceId,
            authResponse: authResponse,
            partnerParams: partnerParams,
            retry: retry,
            smileClientId: smileClientId)
        
        return lambdaRequest!.toJsonString()
        
    }
    
    /* postLambda callback from NetRequest */
    func onPostLambdaComplete( lambdaResponse : LambdaResponse? ){
        
        if (lambdaResponse == nil) {
            onError( sidError: SIDError.PREVIOUS_ENROLL_FAILED )
        }
        else{
            // Step 3 : Upload meta data info.json file
            uploadZip( lambdaResponse: lambdaResponse! )
        }
        
    }
    
    /* Step 3. Upload the meta data info.json file */
    func uploadZip( lambdaResponse : LambdaResponse ) {
        /* Create the metaData info.json file */
        let appData = AppData()
        appData.removeJobResponse()
        let metaData = buildInfoJson(lambdaRequest: lambdaRequest!,
                                     lambdaResponse: lambdaResponse )
        writeMetaData( metaData: metaData )
        
        /* Zip the directory for referenceId.  referenceId is defined
         BaseService.   This class extends BaseService */
        let destinationZipFileURL = doZip()
        
        if( destinationZipFileURL == nil ){
            onError( sidError: SIDError.UNABLE_TO_SUBMIT_COULD_NOT_CREATE_ZIP )
            return
        }
        
        /* Upload the zip file */
        let uploadUrlStr = lambdaResponse.uploadUrl
        if( !isUploadUrlValid( uploadUrl: uploadUrlStr )){
            onError( sidError: SIDError.UNABLE_TO_SUBMIT_COULD_NOT_CREATE_ZIP )
            return
        }
        
        
        netRequest?.upload(fileUrl: destinationZipFileURL!,
                           serverUrlStr: uploadUrlStr)
    }
    
    func onUploadComplete(statusCode: Int) {
        // upload zip is complete
        if (statusCode != NetRequest.HTTP_STATUS_CODE_OK ) {
            onError( sidError: SIDError.REQUEST_FAILED_TRY_AGAIN )
            return;
        }
        // Step 5
        uploadJobStatus()
    }
    


    
    
  
  
    // Step 5 Upload job status
    func uploadJobStatus() {
        if( !(isEnrollMode!) ){
            uploadServiceDelegate?.onStartJobStatus()
        }
        netRequest!.uploadJobStatus(partnerUrl: (sidNetData?.partnerUrl)!,
                                    jobStatusUrl: (sidNetData?.jobStatusUrl)!,
                                    isEnrollMode: isEnrollMode!);
        
    }
    
    func onUploadJobStatusComplete(statusResponse: StatusResponse?) {
        if( isEnrollMode )!{
            onUploadJobStatusCompleteIsEnroll(statusResponse: statusResponse )
        }
        else {
            onUploadJobStatusCompleteAuthenticated(statusResponse: statusResponse )
        }
    }
    
    
    
    func onUploadJobStatusCompleteIsEnroll( statusResponse: StatusResponse? ){
        if( statusResponse == nil ){
            return
        }
      
        let resultText = statusResponse!.result.resultText
     
        if( statusResponse!.isJobComplete() ) &&
            (statusResponse!.isJobSuccess() ) {
                /* success */
                confidenceValue = statusResponse!.result.getConfidenceValue()

                uploadServiceDelegate!.onUpdateServiceComplete(
                    sidError: SIDError.SUCCESS,
                    confidenceValue: confidenceValue,
                    retryFlag: false,
                    partnerParams: statusResponse!.result.partnerParams )
                
                 deleteMetaFolder(referenceId: referenceId!);
        }
        else {
            if (resultText.isEmpty) {
                deleteMetaFolder(referenceId:referenceId!)
                uploadServiceDelegate!.onUpdateServiceComplete(
                    sidError: SIDError.ENROLL_FAILED,
                    confidenceValue: confidenceValue,
                    retryFlag: false,
                    partnerParams: nil)
            } else {
                // Android code was also throwing an exception which
                // was handled by broadcasting another onFailure.  So
                // there were two broadcasts
                
                if( resultText == "Job type requires an ID Card image." ){
                     deleteMetaFolder(referenceId: referenceId!)
                }
                uploadServiceDelegate!.onUpdateServiceComplete(
                    sidError: SIDError.custom(errMsg: resultText),
                    confidenceValue: confidenceValue,
                    retryFlag: false,
                    partnerParams: nil )
            }
        }
        clearMetadata()
    }
    
    
    func onUploadJobStatusCompleteAuthenticated(
        statusResponse: StatusResponse? ){
        if( isCancelled ){
            onError( sidError: SIDError.FAILED_JOB_STATUS_CANCELLED_OR_TIMEOUT)
            return
        }
        if (statusResponse == nil) {
            return
        }
        
        if( statusResponse!.isJobComplete() ) &&
            (statusResponse!.isJobSuccess() ) {
                /* success */
                confidenceValue = statusResponse!.result.getConfidenceValue()
                
                uploadServiceDelegate!.onUpdateServiceComplete(
                    sidError: SIDError.SUCCESS,
                    confidenceValue: confidenceValue,
                    retryFlag: false,
                    partnerParams: statusResponse!.result.partnerParams )
                 deleteMetaFolder(referenceId: referenceId!)
        }
        else{
            deleteMetaFolder(referenceId:referenceId!)
            uploadServiceDelegate!.onUpdateServiceComplete(
                sidError: SIDError.UNABLE_TO_VERIFY,
                confidenceValue: confidenceValue,
                retryFlag: false,
                partnerParams: nil)
        }
    
    
        clearMetadata()
    }
    
    
    func onUpdateJobStatus( msg : String ){
        uploadServiceDelegate?.onUpdateJobStatus( msg: msg )
    }
    
    func onUpdateJobProgress( progress : Int ){
        uploadServiceDelegate?.onUpdateJobProgress( progress: progress )
    }

    func onError( sidError : SIDError ){
        uploadServiceDelegate?.onUpdateError( sidError: sidError,
                                              confidenceValue : confidenceValue,
                                              retryFlag : false,
                                              partnerParams : partnerParams )
    }
    
    
    
    /**************************************************
     Utils
     **************************************************/
    func isUploadUrlValid( uploadUrl : String? ) -> Bool {
        if( uploadUrl == nil ){
            return false
        }
        if( uploadUrl!.isEmpty ){
            return false
        }
        return true
        
    }
    
    
    func getPhoneNumber() -> String {
        // Apple does not allow this.  The app will be rejected.
        return "(000)000-0000"
    }
    
    
    func buildInfoJson( lambdaRequest : LambdaRequest,
                        lambdaResponse : LambdaResponse ) -> MetaData {
        
        let appData = AppData()
        let userInfoJson = UserInfoJson(
            isVerifyProcess: appData.getIsVerifyProcess(defaultVal: false)!,
            userName: appData.getUserName(defaultUserName: "" ),
            fbUserId: appData.getFBUserId(defaultFbUserId: ""),
            fbUserFirstName: appData.getFBUserFirstName(defaultFbUserFirstName: ""),
            fbUserLastName: appData.getFBUserLastName(defaultFbUserLastName: ""),
            fbUserGender: appData.getFBUserGender(defaultVal: ""),
            fbUserEmail: appData.getFBUserEmail(defaultFbUserEmail:""),
            fbUserPhoneNumber: appData.getUserPhoneNumber(defaultUserPhoneNumber: ""),
            countryCode: appData.getCountryCode(defaultCountryCode: ""),
            countryName: appData.getCountryName(defaultCountryName: ""))
        
        
        let miscInfo = MiscInfo(lambdaRequest: lambdaRequest,
                                userInfoJson: userInfoJson,
                                geoInfos: geoInfos!)
        let serverInfo = lambdaResponse.rawJsonString
        
        // Ported from Android code.  SIDUserIdInfo's fields are all empty
        let metaData = MetaData(packageInfo: packageInfo!,
                                miscInfo: miscInfo,
                                serverInfo: serverInfo,
                                sidUserIdInfo: SIDUserIdInfo() )
        
        return metaData
    }
    
    func doZip() -> URL? {
        let siFileManager = SIFileManager()
        let destinationZipFileURL = siFileManager.zipIt(referenceId:referenceId!)
        return destinationZipFileURL
    }
    
    
 
    
    
    
}
