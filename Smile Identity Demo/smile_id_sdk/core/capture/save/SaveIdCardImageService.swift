//
//  SaveIdCardImageService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/8/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class SaveIdCardImageService : BaseSaveService {
    init( referenceId : String ){
        super.init()
        super.referenceId = referenceId
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
       
        let capturedImage = saveFrameData(
            frame: SmileIDSingleton.sharedInstance.idCardFrame!,
            filename: SmileIDSingleton.ID_CARD_FRAME_NAME,
            orientation : 0,
            referenceId : referenceId! )
    SmileIDSingleton.sharedInstance.capturedImagesManager.idCardCapturedImage = capturedImage

        
    }
}
