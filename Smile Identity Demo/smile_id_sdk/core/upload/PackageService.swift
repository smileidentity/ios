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
        
    }
        
    /*
     Save the captured data for later use.
     TODO : Possibly remove this code.
     Don't remove the info.json until the upload is successfull.
     */
    func saveCapturedData( tag : String,
                           sidNetData : SIDNetData ) throws {
        let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager
        
        var metaData = readSavedMetadata()
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
            var captureConfig = initCaptureConfig(sidNetData: sidNetData );
            
            metaData = createCapturedImagesMetaData( isMaxFrameTimeout, captureConfig : captureConfig )
            
            JsonUtils().jsonWrite(getMetaFullFilename(referenceID), new Gson().toJson(metaData));
        }
        
    }
    

    func initCaptureConfig( sidNetData : SIDNetData ) -> CaptureConfig {
        let captureConfig = CaptureConfig()
        captureConfig.lambdaAddress = sidNetData.lambdaUrl
        captureConfig.partnerAddress = sidNetData.partnerUrl
        captureConfig.partnerPort = sidNetData.partnerPort
        captureConfig.sidAddress = sidNetData.sidAddress
        captureConfig.sidPort = sidNetData.sidPort
        return captureConfig
    }
    
    
    func createCapturedImagesMetaData(
        isMaxFrameTimeout : Bool,
        captureConfig : CaptureConfig )
        throws -> MetaData? {
            
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
                /* Selfie preview frame */
                fullFrameInfoPreview = fullFrameInfo
            }
            else if( filename == SmileIDSingleton.ID_CARD_FRAME_NAME ){
                
                /* id card frame */
                fullFrameInfoIDCard = fullFrameInfo
                
                let sidDeviceCameraInfosBack =  SIDDeviceCameraInfos(
                    lensCharacteristics: SmileIDSingleton.sharedInstance.lensCharacteristicsBack,
                    isFront: false);
                metaData.sidDeviceCameraInfosBack = sidDeviceCameraInfosBack
            }
            else{
                /* selfie frames */
                fullFrameInfoArr.append(fullFrameInfo!)
            }
            
        } // for
        
        if( captureConfig.isFrontFacingCamera ){
            
            let sidDeviceCameraInfosFront =  SIDDeviceCameraInfos(
                lensCharacteristics: SmileIDSingleton.sharedInstance.lensCharacteristicsFront,
                isFront: true);
            metaData.sidDeviceCameraInfosFront = sidDeviceCameraInfosFront
        }
            
        if( fullFrameInfoArr.count == 0 ||
            fullFrameInfoPreview == nil ){
                return nil;
        }

        captureConfig.imageProcessingCaps =  ImageProcessingCaps()
   
        captureConfig.idCardType = AppData().getSelectedIdType(IdType.EMPTY))
            
            metaData.setReferenceId(referenceID);
            metaData.setApiVersion(new APIVersion());
            metaData.setSecurityCaps(new SecurityCaps());
            metaData.setFrameInfo(fullFrameInfoArr);
            metaData.setFrameInfoPreviewFull(fullFrameInfoPreview);
            metaData.setFrameInfoIDCard(fullFrameInfoIDCard);
            metaData.setCaptureConfig(captureConfig);
            metaData.setMaxFrameTimeout(isMaxFrameTimeout);
            
            
    } // createCapturedImagesMetaData
    
}

