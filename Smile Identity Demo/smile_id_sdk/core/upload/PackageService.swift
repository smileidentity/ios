//
//  PackageService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/11/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class PackageService : BaseSaveService {


    func packAndSend(  coreRequestData : CoreRequestData ) {
        let appData = AppData()
        if (!appData.isIdTaken()) {
            deleteIdCardImage(referenceId)
        }
        appData.setIdTaken(idTaken: false)
        sendRequest(coreRequestData: coreRequestData)
    }


    func sendRequest( coreRequestData : CoreRequestData ) {
        do {
            // Save the Facebook image to a file, if it exists
            var jsonMetadata : String?
            
            let fbUserImage = SmileIDSingleton.sharedInstance.fbUserImage
            if( fbUserImage != nil ) {
                writeImageToFile(data: fbUserImage!, referenceId: referenceId!, filename: SmileIDSingleton.FB_USER_FRAME_NAME)
            }
        
            let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager
            
            if( coreRequestData.tag?.isEmpty )!{
            }
        } // do
        catch SIDError.TAG_NOT_FOUND {
            // TODO
    }
        
    /*
        Save the captured data for later use.
         TODO : Possibly remove this code.
         Don't remove the info.json until the upload is successfull.
    */
    func saveCapturedData( tag : String,
                           smileIdNetData : SIDNetData ) throws {
        let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager
        
        let metaData = readSavedMetadata()
        if( metaData == nil ){
            clearMetadata();
            deleteMetaFolder(referenceId: SIDReferenceId.DEFAULT_REFERENCE_ID + tag);
        }
        
        if (metaData == nil ) {
            let captureSelfieResponseCode = capturedImagesManager.captureSelfieResponseCode
            
            var isMaxFrameTimeout = false
            if( captureSelfieResponseCode == SmileIDSingleton.SELFIE_RESPONSE_CODE_MAX_FRAME_TIMEOUT){
                isMaxFrameTimeout = true
            }
            
            /* initCaptureConfig : Note that in the Android code the urls in capture config were duplicated in the sidNetData class, so not porting initCaptureConfig method here.
             */
            
              metaData = createCapturedImagesMetaData( isMaxFrameTimeout);
        
        JsonUtils().jsonWrite(getMetaFullFilename(referenceID), new Gson().toJson(metaData));
        }
        
    }
    

    func createCapturedImagesMetaData( isMaxFrameTimeout : Bool )
        throws -> MetaData {
            
            
        var fullFrameInfoPreview : FullFrameInfo?
        var fullFrameInfoIDCard  : FullFrameInfo?
        var fullFrameInfoArr     = [FullFrameInfo]()
            
        let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager
            if( !capturedImagesManager.hasSelfies() ){
                throw SIDError.NO_IMAGE_FOUND
            }
            
        let metaData = MetaData()
        let siFileManager = SIFileFileManager()
            
        let allCapturedImages = capturedImagesManager.getAllCapturedImages()
        for capturedImage in allCapturedImages {
            if( capturedImage.filename!.isEmpty ){
                continue
            }
            let filename = capturedImage.filename!
            let fullFilePath = siFileManager.getFullFilePath(
                referenceId: referenceId!,
                filename: filename )
            if( !siFileManager.fileExists(fullFilePath: fullFilePath )){
                continue
            }
            
            var fullFrameInfo = capturedImage.fullFrameInfo
            if( filename == SmileIDSingleton.PREVIEW_FRAME_NAME ){
                fullFrameInfoPreview = fullFrameInfo
            }
            else if( filename == SmileIDSingleton.ID_CARD_FRAME_NAME ){
                sidDeviceCameraInfosBack = new SIDDeviceCameraInfos(context,
                                                                    fullFilePath,
                                                                    smileIDSingleton.getLensCharacteristicsBack(),
                                                                    false,
                                                                    smileIDSingleton.getPreviewSizeListBack());
                metaData.setSIDDeviceCameraInfosBackCam(sidDeviceCameraInfosBack);
                
                fullFrameInfoIDCard = fullFrameInfo;

            }
            
            
            
            
            
        }
                
    }
    
    
    
    
    
    
    
    
    
}

