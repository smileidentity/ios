//
//  NetRequest.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/31/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation


class NetRequest {
    
    // Notification constants
    static let KEY_UPDATE_JOB_STATUS_MSG    : String     = "keyUpdateJobStatusMsg";
    static let KEY_UPLOAD_JOB_STATUS_RESPONSE : String  =
    "keyUploadJobStatusResponse"
    static let KEY_PROGRESS                 : String    = "keyProgress";
    static let NOTIFICATION_KEY_RAW_VALUE   : String    = "notification_key"
    
    static let JOB_STATUS_REQUEST_SLEEP     : Double    = 0.2       // 200 ms
    static let MAX_INPUT_BUFFER_SIZE        : Int       = 8192
    static let HTTP_BAD_REQUEST             : Int       = 400
    static let HTTP_STATUS_CODE_OK          : Int       = 200
    static let UPLOAD_JOB_STATUS_RETRY_TIMEOUT_SEC
        : Double       = 45.0    // Seconds
    static let UPLOAD_JOB_STATUS_MAX_ATTEMPTS
        : Int     = 35
    // Android code was in milliseconds : 120000
    // iOS is in seconds
    static let HTTP_TIMEOUT                 : Int       = 120;
    
    var isCancelled                         : Bool      = false
    
    var netRequestDelegate                  : NetRequestDelegate?
    let logger                              = SILog()
    
    
    var uploadJobStatusAttemptNum           : Int       = 0
    var uploadJobStatusTimer                : Timer?
    var uploadJobStatusStartTime            : Double    = 0.0
    var uploadJobStatusJsonStr              : String?
    var uploadJobStatusPartnerUrl           : String?
    var uploadJobStatusUrl                  : String?
    
    var authSmileRequestUrl                 : String?
    var isExecuteAuthSmile                  : Bool?
    var jsAuthSmileRequest                  : String?
    
    init( netRequestDelegate : NetRequestDelegate ){
        self.netRequestDelegate = netRequestDelegate
    }
    
    
    
    /* Local callback for when uploadJobStatus is called from executeAuthSmile.
     Android code shows uploadJobStatus being called both from this class,
     from executeAuthSmile, and also from UploadService.   For now,
     the logic is being kept the same */
    func onUploadJobStatusComplete( statusResponse : StatusResponse ){
        isExecuteAuthSmile = false
        if( statusResponse.isJobComplete() ) {
            postAuthSmile()
        }
        else if ( !(statusResponse.error?.isEmpty)! ) {
            let sidError = SIDError.UNABLE_TO_SUBMIT_COULD_NOT_AUTH
            netRequestDelegate?.onError( sidError: sidError )
        }
        
    }
    

    /* called internally from this class only */
    func postAuthSmile() {
        doHttpPost( serverUrl: authSmileRequestUrl!,
                    json: jsAuthSmileRequest!) {
                        /*  This is the completion handler that is called
                         from doHttpPost's uploadTask completion handler */
                        (jsResponse) -> Void in
                        if( jsResponse != nil ){
                            let authSmileResponse = AuthSmileResponse().fromJsonString(
                                jsonFormattedString: jsResponse! )
                            self.netRequestDelegate?.onPostAuthSmileComplete(authSmileResponse: authSmileResponse!)
                        }
                        else{
                            self.netRequestDelegate?.onPostAuthSmileComplete(
                                authSmileResponse: nil)
                        }
        }
    }
    
    /* called externally */
    func postAuthSmile( partnerUrl : String,
                        authUrl : String,
                        jobStatusUrl : String,
                        jobType : Int,
                        isEnrollMode: Bool ) {
        authSmileRequestUrl = partnerUrl + authUrl
        let appData = AppData()
        
        let userId = appData.getUserId( defaultUserId: "" )
        let isIdPresent = appData.getIsIDPresent(defaultVal: false)

        let authSmileRequest = AuthSmileRequestJson(
            jobType: jobType,
            userId:userId!,
            isIdPresent:isIdPresent,
            isEnrollMode: isEnrollMode)
        
        jsAuthSmileRequest = authSmileRequest.toJsonString()
        
        if (isEnrollMode) {
            // Enroll mode
            postAuthSmile()
            
        } // isEnroll Mode
        else {
            // uploadJobStatus is called from here, and also from UploadService.
            isExecuteAuthSmile = true
            uploadJobStatus(partnerUrl: partnerUrl, jobStatusUrl: jobStatusUrl, isEnrollMode: !isEnrollMode )
        }
    }
    
    /*
     Upload json lambda request.
     Returns an UploadDataResponse object in the completion hander.
     Android code called this function 'transmitToServer'
     */
    func postLambda( jsLambdaRequest  : String,
                     lambdaUrl        : String ) {
        doHttpPost( serverUrl: lambdaUrl,
                    json: jsLambdaRequest ) {
                        /*  This is the completion handler that is called
                         from doHttpPost's uploadTask completion handler */
                        (jsResponse) -> Void in
                        if( jsResponse != nil ){
                            let lambdaResponse = LambdaResponse().fromJsonString(
                                jsonFormattedString: jsResponse! )
                            self.netRequestDelegate?.onPostLambdaComplete(lambdaResponse: lambdaResponse! )
                        }
                        else{
                            self.netRequestDelegate?.onPostLambdaComplete(
                                lambdaResponse: nil )
                        }
        }
    }
    
    
    
    func uploadJobStatus( partnerUrl: String,
                          jobStatusUrl : String,
                          isEnrollMode : Bool ) {
        
        let appData = AppData()
        
        let uploadJobStatus = UploadJobStatus(
            userId: appData.getUserId( defaultUserId: "" )!,
            smileClientId: appData.getSmileClientId( defaultSmileClientId: "" )!,
            lastEnrolledJobId: appData.getLastEnrollJobId( defaultLastEnrollJobId: "" )!,
            jobId: appData.getJobId(defaultJobId: "")!,
            isEnrollMode: !isEnrollMode)
        
        uploadJobStatusJsonStr = uploadJobStatus.toJsonString()
        uploadJobStatusAttemptNum = 0
        uploadJobStatusStartTime = Date().timeIntervalSince1970
        uploadJobStatusPartnerUrl = partnerUrl
        uploadJobStatusUrl = jobStatusUrl
        
        if uploadJobStatusTimer == nil {
            uploadJobStatusTimer = Timer.scheduledTimer(timeInterval: NetRequest.JOB_STATUS_REQUEST_SLEEP,
                                                        target: self,
                                                        selector:#selector(self.scheduledUploadJobStatus),
                                                        userInfo: nil,
                                                        repeats: true)
        }
        
        
    }
    
    
    /* Called from a timer, so we are using @objc */
    @objc func scheduledUploadJobStatus() {
        
        let networkingUtils = SIDNetworkUtils()
        let currentTimeSec =  Date().timeIntervalSince1970
        var timedOut = false
        if( ( currentTimeSec - uploadJobStatusStartTime ) >= NetRequest.UPLOAD_JOB_STATUS_RETRY_TIMEOUT_SEC ){
            timedOut = true
        }
        
        if( isCancelled || timedOut || uploadJobStatusAttemptNum > NetRequest.UPLOAD_JOB_STATUS_MAX_ATTEMPTS ){
            stopUploadJobStatusTimer()
            return
        }
        
        
        if( uploadJobStatusAttemptNum % 10 == 0 ) &&
            ( uploadJobStatusAttemptNum != 0 ){
            let msg = "Inside while loop Attempt No : " + String(uploadJobStatusAttemptNum) +
                " - Internet connection :" +
                String( networkingUtils.isConnected() )
            netRequestDelegate?.onUpdateJobStatus( msg: msg )
        }
        
        doHttpPost(serverUrl: self.uploadJobStatusPartnerUrl! + self.uploadJobStatusUrl!,
                   json: self.uploadJobStatusJsonStr!) { (jsResponse) -> Void in
                    
                    if (jsResponse != nil) {
                        let statusResponse = StatusResponse().fromJsonString(jsonFormattedString: jsResponse!)
                        if( statusResponse != nil ){
                            
                            let logOutput = "uploadJobStatus response:--" + (statusResponse!.rawJsonString) + " request:" +     self.uploadJobStatusJsonStr!
                            self.logger.SIPrint(logOutput: logOutput);
                            
                            if( statusResponse!.isJobComplete() ) {
                                /* success */
                                let msg = "Total attempts to check job completion : " + String(self.uploadJobStatusAttemptNum)
                                self.netRequestDelegate?.onUpdateJobStatus( msg: msg )
                                self.stopUploadJobStatusTimer()
                                if( !self.isExecuteAuthSmile! ){
                                    self.netRequestDelegate?.onUploadJobStatusComplete( statusResponse: statusResponse! )
                                }
                                else{
                                    // Local callback - from android port
                                    self.onUploadJobStatusComplete( statusResponse: statusResponse! )
                                }
                            }
                            else if( !statusResponse!.error!.isEmpty ) {
                                /* failure.
                                 job is not complete,
                                 and there is an error.
                                 Notify with the error, and stop trying. */
                                self.stopUploadJobStatusTimer()
                                
                                if( !self.isExecuteAuthSmile! ){
                                    self.netRequestDelegate?.onUploadJobStatusComplete( statusResponse: statusResponse! )
                                }
                                else{
                                    // Local callback - from android port
                                    self.onUploadJobStatusComplete( statusResponse: statusResponse! )
                                }
                            }
                            
                            self.uploadJobStatusAttemptNum =
                                self.uploadJobStatusAttemptNum + 1
                        }
                    }
        }
        
    }

    
    func stopUploadJobStatusTimer() {
        if uploadJobStatusTimer != nil {
            uploadJobStatusTimer?.invalidate()
            uploadJobStatusTimer = nil
        }
    }
    
    
    
    
    
    /*
     Perform Http Post request
     Inputs :
     serverUrl   : The url where the data is posted
     json        : The json data that is posted
     completion  : The completion handler that is called after the http post request is finished.   The json formatted response string is returned to the completion handler.
     */
    func doHttpPost( serverUrl  : String,
                     json       : String,
                     completion: @escaping (String?) -> () ) {
        let url = URL(string: serverUrl)!
        
        let uploadData = json.data(using: .utf8)!
        
        var request = URLRequest(url: url)
        
        request.timeoutInterval = TimeInterval(NetRequest.HTTP_TIMEOUT)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(
            with: request,
            from: uploadData ) { data, response, error in
                
                if let error = error {
                    self.logger.SIPrint(logOutput: "error: \(error)")
                    completion(nil)
                    return
                }
                
                if let response = response as? HTTPURLResponse{
                    let statusCode = response.statusCode
                    
                    if (statusCode == NetRequest.HTTP_BAD_REQUEST ) {
                        // TODO - Caller will check for nil,
                        // and return  SIDError.UNABLE_TO_SUBMIT_TRY_AGAIN
                        completion(nil)
                        return
                        // throw SIDError.UNABLE_TO_SUBMIT_TRY_AGAIN
                    }
                    
                    let jsResponse = String(data: data!,
                                            encoding: .utf8)
                    /* now call the caller's completion handler */
                    completion(jsResponse)
                    return
                }
        }
        task.resume()
        
    }
    
    
    func cancel() {
        isCancelled = true
    }
    
    
    
    /* Upload a file using the given fileUrlStr.
     Return the status code as an Int, using a completion handler.
     Called from UploadService for uploading the zip file.
     */
    func upload( fileUrl        : URL,
                 serverUrlStr   : String ) {
        
        let serverUrl = URL(string: serverUrlStr)!
        
        var request = URLRequest(url: serverUrl)
        request.timeoutInterval = TimeInterval(NetRequest.HTTP_TIMEOUT)
        request.httpMethod = "PUT"
        request.setValue("application/zip", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(
            with: request,
            fromFile : fileUrl ) { data, response, error in
                if let error = error {
                    self.logger.SIPrint(logOutput: "error: \(error)")
                    self.netRequestDelegate?.onUploadComplete(statusCode: 0 )
                }
                
                if let response = response as? HTTPURLResponse{
                    
                    let statusCode = response.statusCode
                    self.netRequestDelegate?.onUploadComplete(statusCode: statusCode )
                    return
                }
                
                /*
                 if let mimeType = response.mimeType,
                 mimeType == "application/json",
                 let data = data,
                 let dataString = String(data: data, encoding: .utf8) {
                 print ("got data: \(dataString)")
                 }
                 */
        }
        task.resume()
        
    }
    
    
    
    
    
    
    
    
    func logError( request : AuthSmileRequestJson,
                   response : AuthSmileResponse,
                   isEnroll : Bool ) {
        var logOutput : String?
        if( isEnroll ){
            logOutput = "executeAuthSmile enroll response:--"
        }
        else{
            logOutput = "executeAuthSmile auth response:--"
        }
        
        logOutput = logOutput! + (response.getRawJsonString()) + " request:" + request.toJsonString()
        
        logger.SIPrint(logOutput: logOutput!)
    }
    
    
    
    
}

