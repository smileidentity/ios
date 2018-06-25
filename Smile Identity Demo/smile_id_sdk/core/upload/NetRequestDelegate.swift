//
//  NetRequestDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/31/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

protocol NetRequestDelegate {
    // In android, this was used to track progress when uploading zip.
    // In iOS, the upload is done in one chunk
    func onUpdateJobProgress( progress : Int )

    func onUpdateJobStatus( msg : String )
    
    func onPostAuthSmileComplete( authSmileResponse : AuthSmileResponse? )
    
    // Could use a completion handler just as well as a delegate for this one,
    // but for consistancy, will use a delegate.
    // This is because the uploadJobStatus uses a delegate, because it is
    // using a timer, so can't return objects in a completion handler
    func onPostLambdaComplete( lambdaResponse : LambdaResponse? )
    
    func onUploadComplete( statusCode : Int )
    
    func onUploadJobStatusComplete( statusResponse : StatusResponse? )
    
    // Android code would throw errors, here we will use a delegate,
    // and the delegate will handle it.
    func onError( sidError : SIDError )
    
}

