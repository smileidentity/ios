//
//  CapturedImageManager.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/6/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class CapturedImagesManager {
    
    /* 0 = success; 1 = maxFrameTimeout, other values are reserved for future use
     */
    var captureSelfieResponseCode : Int?
    var referenceID : String?
    
    var numImagesCaptured           : Int?
    
    var selfieCapturedImages        = [CapturedImage]()
    var idCardCapturedImage         : CapturedImage?

    
    func getAllCapturedImages() -> [CapturedImage]{
        
        var capturedImages        = [CapturedImage]()
        for capturedImage in selfieCapturedImages {
            capturedImages.append( capturedImage )
        }
        if( idCardCapturedImage != nil ){
            capturedImages.append( idCardCapturedImage! )
        }
        
        return capturedImages
        
    }
    
    func hasIdCardImage() -> Bool {
        if( idCardCapturedImage == nil ){
            return false
        }
        else{
            return true
        }
    }
    
    func hasSelfies() -> Bool {
        if( selfieCapturedImages.count > 0 ){
            return true
        }
        else{
            return false
        }
    }
    
    func clearSelfiesEntry() {
        self.selfieCapturedImages.removeAll()
    }
    
    func addSelfieCapData( capturedImage : CapturedImage ) {
        self.selfieCapturedImages.append(capturedImage);
    }
    
  
   

}
