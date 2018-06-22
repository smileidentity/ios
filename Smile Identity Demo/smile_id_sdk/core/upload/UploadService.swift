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
    
    init( uploadServiceDelegate : UploadServiceDelegate ){
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
        
        if( requestNewToken! || authSmileResponse != nil ){
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
            uploadServiceDelegate!.onError( sidError: SIDError.PREVIOUS_ENROLL_FAILED )
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
        
        /* Upload the zip file */
        let uploadUrlStr = lambdaResponse.uploadUrl
        if( !isUploadUrlValid( uploadUrl: uploadUrlStr )){
            onError( sidError: SIDError.UNABLE_TO_SUBMIT_COULD_NOT_CREATE_ZIP )
            return
        }
        
        
        netRequest?.upload(fileUrl: destinationZipFileURL,
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
    
    func broadcastJobStatusResponse( statusResponse : StatusResponse,
                                     errMsg         : String ) {
        if (statusResponse.isJobComplete()) {
            if( statusResponse.isJobSuccess() ) {
                broadcastSuccess(statusResponse.result.getPartnerParams
                clearMetadata();
                deleteMetaFolder(referenceID);
            }
            
        } else {
            uploadServiceDelegate?.onError(
                sidError: SIDError.custom(errMsg: errMsg ) )
        }
        
    }
    
    func onUploadJobStatusCompleteIsEnroll(
        statusResponse: StatusResponse? ){
        if (statusResponse != nil ) {
            // Android code sets confidence value before checking isJobComplete first for enroll
            
            let confidenceValue = statusResponse!.result.confidenceValue
            broadcastJobStatusResponse(statusResponse: statusResponse!,
                errMsg: statusResponse!.result.resultText )
 
            
        }
    }
    
 
    func onUploadJobStatusCompleteAuthenticated(
        statusResponse: StatusResponse? ){
        if( isCancelled ){
             onError( sidError: SIDError.FAILED_JOB_STATUS_CANCELLED_OR_TIMEOUT)
        }
        else{
            if (statusResponse != nil ) {
                
                if( statusResponse!.isJobComplete() ) {
                    // Android code sets confidenceValue after checking isJobComplete for auth
                    let confidenceValue = statusResponse!.result.confidenceValue
                }
                
                broadcastJobStatusResponse(statusResponse: statusResponse!,
                    errMsg: SIDError.FAILED_JOB_STATUS_CANCELLED_OR_TIMEOUT.message )
                
                
            }
            else{
                
            }
        }
    }
    
    
    
    func onUpdateJobStatus( msg : String ){
        // TODO : Pass msg back to UI.
    }
    
    

    
    func onError( sidError : SIDError ){
        uploadServiceDelegate?.onError( sidError: sidError )
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
    
    func doZip() -> URL {
        let siFileManager = SIFileFileManager()
        let destinationZipFileURL = siFileManager.zipIt(referenceId:referenceId!)
        return destinationZipFileURL
    }
    
    

    
    
  
  
    
    
    
    
    

    
    
    
}
