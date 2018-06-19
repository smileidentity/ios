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
    static let UPLOAD_JOB_STATUS_RETRY_TIMEOUT_SEC
                                            : Double       = 45.0    // Seconds
    static let UPLOAD_JOB_STATUS_MAX_ATTEMPTS
                                            : Int     = 35
    // Android code was in milliseconds : 120000
    // iOS is in seconds
    static let HTTP_TIMEOUT                 : Int       = 120;
    
    var attempt                             : Int       = 0
    var isCancelled                         : Bool      = false
    
    var netRequestDelegate                  : NetRequestDelegate?
    let logger                              = SILog()
    
    
    var uploadJobStatusAttemptNum           : Int       = 0
    var uploadJobStatusTimer                : Timer?
    var uploadJobStatusStartTime            : Double    = 0.0
    var uploadJobStatusJsonStr              : String?
    var uploadJobStatusPartnerUrl           : String?
    var uploadJobStatusUrl                  : String?
    
    
    
    
    func executeAuthSmile( partnerUrl : String,
                           authUrl : String,
                           jobStatusUrl : String,
                           jobType : Int,
                           isEnrollMode: Bool) throws /*-> AuthSmileResponse?*/ {
        
        let response : AuthSmileResponse?
        let appData = AppData()

        let userId = appData.getUserId( defaultUserId: "" )
        let isIdPresent = appData.getIsIDPresent(defaultIsIDPresent: false);
  
        let authSmileRequest = AuthSmileRequestJson(
            jobType: jobType,
            userId:userId!,
            isIdPresent:isIdPresent,
            isEnrollMode: isEnrollMode)
        
        let jobRequest = authSmileRequest.toJsonString()
        
        if (isEnrollMode) {
            // Enroll mode
            doHttpPost(target: AuthSmileResponse(),
                       serverUrl: partnerUrl + authUrl,
                       json: jobRequest) { (jsonResponse) -> Void in
                        
                        self.logError( request: authSmileRequest, response: jsonResponse as! AuthSmileResponse, isEnroll: true )
            }
 
        } // isEnroll Mode
        else {
            /*
            // Authentication mode
            let statusResponse = uploadJobStatus(partnerUrl: partnerUrl, jobStatusUrl: jobStatusUrl, isAuthenticationMode: true);
            if (statusResponse != nil && statusResponse.jobComplete) {
                
                doHttpPost(target: AuthSmileResponse(),
                           serverUrl: partnerUrl + authUrl,
                           json: jobRequest) { (jsonResponse) -> Void in
                            
                            self.logError( request: authSmileRequest, response: jsonResponse as! AuthSmileResponse, isEnroll: false )
                }
                
                
            }
                
            else if ( !statusResponse.error.isEmpty ) {
                throw new SIDException("Auth " + statusResponse.getError());
            }
             */
        }
 
 
        return response
  
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
                    
                    if let mimeType = response.mimeType,
                        mimeType == "application/json",
                        let data = data,
                        let jsResponse = String(data: data,
                                                  encoding: .utf8) {
                        completion(jsResponse)
                        return
                    }
                    
                    completion(nil)
                    
                }
        }
        task.resume()
        
    }
    
    

    
 
  
    
    
    func uploadJobStatus( partnerUrl: String,
                          jobStatusUrl : String,
                          isAuthenticationMode : Bool ) {
        
        let appData = AppData()
        
        let uploadJobStatusJson = UploadJobStatusJson(
            userId: appData.getUserId( defaultUserId: "" )!,
            smileClientId: appData.getSmileClientId( defaultSmileClientId: "" )!,
            lastEnrolledJobId: appData.getLastEnrollJobId( defaultLastEnrollJobId: "" )!,
            jobId: appData.getJobId(defaultJobId: "")!,
            isAuthenticationMode: isAuthenticationMode)
        
        uploadJobStatusJsonStr = uploadJobStatusJson.toJsonString()
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
            notifyUploadJobStatusMsg(msg: msg )
        }
  
        
        doHttpPost(serverUrl: self.uploadJobStatusPartnerUrl! + self.uploadJobStatusUrl!,
                   json: self.uploadJobStatusJsonStr!) { (jsResponse) -> Void in
                    
            if (jsResponse != nil) {
                let statusResponse = StatusResponse().fromJsonString(jsonFormattedString: jsResponse!)
                if( statusResponse != nil ){
                    
                    let logOutput = "uploadJobStatus response:--" + (statusResponse!.rawJsonString) + " request:" + self.uploadJobStatusJsonStr!
                        self.logger.SIPrint(logOutput: logOutput);
                    
                    if( statusResponse!.isJobComplete() ) {
                        /* success */
                        let msg = "Total attempts to check job completion : " + String(self.attempt)
                        self.notifyUploadJobStatusMsg( msg: msg )
                        self.stopUploadJobStatusTimer()
                    }
                    else if( !statusResponse!.error.isEmpty ) {
                        /* failure.
                         job is not complete,
                         and there is an error.
                         Notify with the error, and stop trying. */
                        self.stopUploadJobStatusTimer()
                        self.notifyUploadJobStatus(statusResponse: statusResponse)
                    }
                    
                    self.attempt = self.attempt + 1
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
    
    
  
    
    
  

  
    
    func transmitToServer( jsLambdaRequest  : String,
                           lambdaUrl        : String,
                           completion: @escaping (UploadDataResponse?) -> () ) {
        
        doHttpPost(target:UploadDataResponse(),
                   serverUrl: lambdaUrl,
                   json: jsLambdaRequest) { (jsonResponse) -> Void in
                    
                    completion( jsonResponse as? UploadDataResponse )
            }
    }
    
    
  
    
    /* Upload a file using the given url.
     Return the status code as an Int, using a completion handler */
    func upload(fileUrl : URL,
                serverUrl : String,
                completion: @escaping (Int?) -> () ) throws {
        
        let url = URL(string: serverUrl)!
        var request = URLRequest(url: url)
        
        request.timeoutInterval = TimeInterval(NetRequest.HTTP_TIMEOUT)
        request.httpMethod = "PUT"
        request.setValue("application/zip", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(
            with: request,
            fromFile : fileUrl ) { data, response, error in
                if let error = error {
                    self.logger.SIPrint(logOutput: "error: \(error)")
                    completion(nil)
                }
                
                if let response = response as? HTTPURLResponse{
                    /* TODO - caller needs to get the statusCode from this.
                     so implement a completion handler for the caller, because this is async.
                     
                     See : https://grokswift.com/completion-handlers-in-swift/
                     https://stackoverflow.com/questions/47258733/how-to-return-an-object-from-a-method-that-contains-a-datatask
                     
                     
                     Usage :
                     let netRequest = NetRequest()
                     netRequest.upload(fileUrl: myFileUrl,
                     serverUrl: myServerUrl ) {
                     statusCode in
                     if let statusCode = statusCode {
                     print(statusCode)
                     }
                     }
                     
                     */
                    
                    let statusCode = response.statusCode
                    completion(statusCode)
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
    
    
    
    func cancel() {
        isCancelled = true
    }
    
    func notifyProgress( progress : Int ){
        // netRequestDelegate?.onUploadProgress( progress: progress )
        let notificationData = [NetRequest.KEY_PROGRESS : progress]
        NotificationCenter.default.post(name: Notification.Name(rawValue: NetRequest.NOTIFICATION_KEY_RAW_VALUE),object: self, userInfo: notificationData)
    }
    func notifyUploadJobStatusMsg( msg : String ){
        // netRequestDelegate?.onUpdateJobStatus( msg: msg )
        // Use NotificationCenter
        let notificationData = [NetRequest.KEY_UPDATE_JOB_STATUS_MSG : msg]
        NotificationCenter.default.post(name: Notification.Name(rawValue: NetRequest.NOTIFICATION_KEY_RAW_VALUE),object: self, userInfo: notificationData)
    }
    
    func notifyUploadJobStatus( statusResponse : StatusResponse ){
        // netRequestDelegate?.onUpdateJobStatus( msg: msg )
        // Use NotificationCenter
        let notificationData = [NetRequest.KEY_UPLOAD_JOB_STATUS_RESPONSE : statusResponse]
        NotificationCenter.default.post(name: Notification.Name(rawValue: NetRequest.NOTIFICATION_KEY_RAW_VALUE),object: self, userInfo: notificationData)
    }

    

}
