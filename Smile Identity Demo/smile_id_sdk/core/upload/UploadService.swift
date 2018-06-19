//
//  UploadService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/13/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class UploadService {
    var referenceId : String?
    
    var isCancelled : Bool = false // TODO wire cancelled functionality
    
    func start( coreRequestData : CoreRequestData,
                jsMetaData      : String ){
        do {
            let sidNetData = coreRequestData.sidNetData
            let partnerParams = coreRequestData.partnerParams
            
            let requestNewToken = coreRequestData.requestNewToken
            let retry = coreRequestData.retry
            let isEnrollMode = coreRequestData.isEnrollMode

            isCancelled = false
            
            // TODO wire start job status broadcast
            let appData = AppData()
            let sAuthResponse = appData.getAuthSmileResponse(defaultVal: nil )
            var authSmileResponse : AuthSmileResponse?
            if( sAuthResponse != nil ){
                authSmileResponse = AuthSmileResponse().fromJsonString( jsonFormattedString: sAuthResponse! )
            }
            if( requestNewToken! || authSmileResponse != nil ){
                let netRequest = NetRequest()
                try authSmileResponse = netRequest.executeAuthSmile(
                    partnerUrl: sidNetData!.partnerUrl,
                    authUrl: sidNetData!.authUrl,
                    jobStatusUrl: sidNetData!.jobStatusUrl,
                    jobType: coreRequestData.jobType!,
                    isEnrollMode: isEnrollMode! )
                appData.setAuthSmileResponse(response: authSmileResponse);
            }
            
            // TODO broadcast end job status
            
            if( ( authSmileResponse != nil ) && !isCancelled ) {
                let jsLambdaRequest = buildLambdaRequest(
                    phoneNumber: getPhoneNumber(), // Apple does not support this
                    referenceId: referenceId!,
                    deviceId: UIDevice.current.identifierForVendor!.uuidString,
                    authResponse: authSmileResponse!,
                    partnerParams: partnerParams!,
                    retry: retry!,
                    isEnrollMode: isEnrollMode!)
                
                let netRequest = NetRequest()
                let uploadDataResponse = netRequest.tr
                
                
            }
            
            
        } // do
        catch {
            
        }
        
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
        
        let lambdaRequestJson = LambdaRequestJson(
            phoneNumber: phoneNumber,
            referenceId: referenceId,
            deviceId: deviceId,
            authResponse: authResponse,
            partnerParams: partnerParams,
            retry: retry,
            smileClientId: smileClientId)
        
        return lambdaRequestJson.toJsonString()
        
    }
    
    
    func getPhoneNumber() -> String {
        // Apple does not allow this.  The app will be rejected.
        return "(000)000-0000"
    }
    
    
    
}
