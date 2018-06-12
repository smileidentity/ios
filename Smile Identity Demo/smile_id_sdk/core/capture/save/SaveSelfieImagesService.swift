//
//  SaveSelfieImagesService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/8/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation


class SaveSelfieImagesService : BaseSaveService {
    
    var responseCode : Int?
    
    init( referenceId : String, responseCode : Int ){
        super.init()
        super.referenceId = referenceId
        self.responseCode = responseCode
    }
    
    func start() {
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.doSave()
            
            /*  Not necessary to notify the ui thread when this is done
                DispatchQueue.main.async {
                }
            */
        }
    }
    
    
    func doSave() {
        let siFileManager = SIFileFileManager()
        siFileManager.deletePreviewFrames(referenceID: referenceId!)
        SmileIDSingleton.sharedInstance.capturedImagesManager.referenceID = referenceId
        SmileIDSingleton.sharedInstance.capturedImagesManager.numImagesCaptured = SmileIDSingleton.sharedInstance.framesList.count
        SmileIDSingleton.sharedInstance.capturedImagesManager.captureSelfieResponseCode = responseCode
        SmileIDSingleton.sharedInstance.capturedImagesManager.clearSelfiesEntry();
        
        /* Write the frames out to disk */
        var filename : String?
        for frameData in SmileIDSingleton.sharedInstance.framesList {
            
            filename = String(format: "SID_%04d.jpg", frameData.frameNum! )
            
            let capturedImage = saveFrameData(
                frame: frameData,
                filename: filename!,
                orientation: 0,
                referenceId: referenceId! )
            SmileIDSingleton.sharedInstance.capturedImagesManager.selfieCapturedImages.append( capturedImage )
            
        }
        
        /* write the preview frame to disk */
        let capturedImage = saveFrameData(
            frame: SmileIDSingleton.sharedInstance.previewFrame!,
            filename: SmileIDSingleton.PREVIEW_FRAME_NAME,
            orientation : 0,
            referenceId : referenceId! )
        
        /* Note that Android code also appends preview image in the capturedImagesManager.selfieCapturedImages.
         */
        SmileIDSingleton.sharedInstance.capturedImagesManager.selfieCapturedImages.append( capturedImage )
        
        
        /* reclaim space */
        SmileIDSingleton.sharedInstance.previewFrame = nil
        SmileIDSingleton.sharedInstance.setFramesList(
            framesList: [] )
    }
    
    
}
