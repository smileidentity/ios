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
            SIFileFileManager().deleteIDCardImage(referenceID: referenceId!);
        }
        appData.setIdTaken(idTaken: false)
        sendRequest(coreRequestData: coreRequestData)
    }
    
    
    func sendRequest( coreRequestData : CoreRequestData ) {
        do {
            // Save the Facebook image to a file, if it exists
            var jsPackageInfo : String?
            
            let fbUserImage = SmileIDSingleton.sharedInstance.fbUserImage
            if( fbUserImage != nil ) {
                writeImageToFile(data: fbUserImage!, referenceId: referenceId!, filename: SmileIDSingleton.FB_USER_FRAME_NAME)
            }
            
            if( coreRequestData.tag?.isEmpty )!{
                try jsPackageInfo = getPackageInfoJson(
                    sidNetData: coreRequestData.sidNetData!)
                if( jsPackageInfo == nil ){
                    throw SIDError.DATA_PACKAGING_FAILED
                }
                
                AppData().setPackageInformation(
                    packageInformation: jsPackageInfo!)
                
                let uploadService = UploadService()
                uploadService.start(coreRequestData: coreRequestData, jsMetaData: jsPackageInfo!);
            }
            else{
                let metaData = readSavedMetadata()
                let packageInfo = metaData.packageInfo
                jsPackageInfo = packageInfo.fromJsonString()
            }
        } // do
        catch SIDError.TAG_NOT_FOUND {
            // TODO
        }
        catch{
            
        }
        
    }
    
    
    func getPackageInfoJson( sidNetData : SIDNetData ) throws -> String? {
        var jsPackageInfo : String?
        let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager
        if( !capturedImagesManager.hasSelfies() ){
            throw SIDError.NO_IMAGE_FOUND
        }
       
        var captureConfig = initCaptureConfig(sidNetData: sidNetData )
        
        var packageInfo = try createCapturedImagesPackageInfo( isMaxFrameTimeout: isMaxFrameTimeout(), captureConfig : captureConfig )
        
        if (packageInfo != nil) {
            jsPackageInfo = packageInfo.fromJsonString()
        }
        return jsPackageInfo
    }
    
    /*
     Save the captured data for later use.
     TODO : Possibly remove this code.
     Don't remove the info.json until the upload is successfull.
     */
    func saveCapturedData( tag : String,
                           sidNetData : SIDNetData ) throws {
        
        var metaData = readSavedMetadata()
        var packageInfo = metaData.packageInfo
  
        if( packageInfo == nil ){
            clearMetadata();
            deleteMetaFolder(referenceId: SIDReferenceId.DEFAULT_REFERENCE_ID + tag);
        }
        
        if (packageInfo == nil ) {
            let captureConfig = initCaptureConfig(sidNetData: sidNetData );
            
            try packageInfo = createCapturedImagesPackageInfo( isMaxFrameTimeout: isMaxFrameTimeout(), captureConfig : captureConfig )
            
            metaData.packageInfo = packageInfo
            writeMetaData( metaData: metaData! )
        }
        
    }
    
    
    func writeMetaData( metaData : MetaData ) {
        JsonUtils().jsonWrite(getMetaFullFilename(referenceID), new Gson().toJson(metaData));
    }
    
    
  
    
    
    
    

    
    
    func createCapturedImagesPackageInfo(
        isMaxFrameTimeout : Bool,
        captureConfig : CaptureConfig )
        throws -> PackageInfo? {
            
        var fullFrameInfoPreview : FullFrameInfo?
        var fullFrameInfoIDCard  : FullFrameInfo?
        var fullFrameInfoArr     = [FullFrameInfo]()
        
        let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager
        if( !capturedImagesManager.hasSelfies() ){
            throw SIDError.NO_IMAGE_FOUND
        }
            
        let packageInfo = PackageInfo()
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
            
            if( filename == SmileIDSingleton.PREVIEW_FRAME_NAME ){
                /* Selfie preview frame */
                fullFrameInfoPreview = capturedImage.fullFrameInfo
            }
            else if( filename == SmileIDSingleton.ID_CARD_FRAME_NAME ){
                
                /* id card frame */
                fullFrameInfoIDCard = capturedImage.fullFrameInfo
                
                let sidDeviceCameraInfosBack =  SIDDeviceCameraInfos(
                    lensCharacteristics: SmileIDSingleton.sharedInstance.lensCharacteristicsBack,
                    isFront: false);
                packageInfo.sidDeviceCameraInfosBack = sidDeviceCameraInfosBack
            }
            else{
                /* selfie frames */
                fullFrameInfoArr.append(capturedImage.fullFrameInfo!)
            }
            
        } // for
        
        if( captureConfig.isFrontFacingCamera ){
            
            let sidDeviceCameraInfosFront =  SIDDeviceCameraInfos(
                lensCharacteristics: SmileIDSingleton.sharedInstance.lensCharacteristicsFront,
                isFront: true);
            packageInfo.sidDeviceCameraInfosFront = sidDeviceCameraInfosFront
        }
            
        if( fullFrameInfoArr.count == 0 ||
            fullFrameInfoPreview == nil ){
                return nil;
        }

        captureConfig.imageProcessingCaps =  ImageProcessingCaps()
   
            captureConfig.idCardType = AppData().getSelectedIdType(defaultSelectedIdType: IdType.EMPTY)!
            
            packageInfo.referenceId = referenceId
            packageInfo.apiVersion = APIVersion()
            packageInfo.securityCaps = SecurityCaps()
            packageInfo.frameInfo = fullFrameInfoArr
            packageInfo.frameInfoPreviewFull = fullFrameInfoPreview
            packageInfo.frameInfoIDCard = fullFrameInfoIDCard
            packageInfo.captureConfig = captureConfig
            packageInfo.isMaxFrameTimeout = isMaxFrameTimeout

            
            
    } // createCapturedImagesPackageInfo
    
    
    
    func initCaptureConfig( sidNetData : SIDNetData ) -> CaptureConfig {
        let captureConfig = CaptureConfig()
        captureConfig.lambdaAddress = sidNetData.lambdaUrl
        captureConfig.partnerAddress = sidNetData.partnerUrl
        captureConfig.partnerPort = sidNetData.partnerPort
        captureConfig.sidAddress = sidNetData.sidAddress
        captureConfig.sidPort = sidNetData.sidPort
        return captureConfig
    }
    
    func isMaxFrameTimeout() -> Bool {
        let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager

        var isMaxFrameTimeout = false
        let captureSelfieResponseCode = capturedImagesManager.captureSelfieResponseCode
        
        if( captureSelfieResponseCode == SmileIDSingleton.SELFIE_RESPONSE_CODE_MAX_FRAME_TIMEOUT){
            isMaxFrameTimeout = true
        }
        
        return isMaxFrameTimeout

    }
    
}

