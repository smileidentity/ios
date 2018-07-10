//
//  PackageService.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/11/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class PackageService : BaseSaveService {

    var packageServiceDelegate                  : PackageServiceDelegate?
    
    init( referenceId : String ){
        super.init()
        super.referenceId = referenceId
    }
    
    func packAndSend( coreRequestData : CoreRequestData,
                      packageServiceDelegate : PackageServiceDelegate ) {
        self.packageServiceDelegate = packageServiceDelegate
        
           
        let appData = AppData()
        if (!appData.isIdTaken(defaultVal: false)) {
            SIFileManager().deleteIDCardImage(referenceId: referenceId!);
        }
        appData.setIdTaken(idTaken: false)
        sendRequest(coreRequestData: coreRequestData)
    }
    
    
    func sendRequest( coreRequestData : CoreRequestData ) {
        do {
            // Save the Facebook image to a file, if it exists
            var packageInfo : PackageInfo?
            
            let fbUserImage = SmileIDSingleton.sharedInstance.fbUserImage
            if( fbUserImage != nil ) {
                writeImageToFile(data: fbUserImage!, referenceId: referenceId!, filename: SmileIDSingleton.FB_USER_FRAME_NAME)
            }
            
            if( coreRequestData.tag?.isEmpty )!{
                packageInfo = try getPackageInfoJson(
                    sidNetData: coreRequestData.sidNetData!)
                
                if( packageInfo == nil ){
                    throw SIDError.DATA_PACKAGING_FAILED
                }

                AppData().setPackageInformation(
                    packageInformation: (packageInfo!.toJsonString()))
                
            }
            else{
                let jsMetaData = readMetadata()
                let metaData = MetaData().fromJsonString(jsonString: jsMetaData! )
                packageInfo = metaData?.packageInfo
             }
            
            packageServiceDelegate!.onPackagingComplete(packageInfo:  packageInfo!, coreRequestData: coreRequestData )
 

        } // do

        /*
        catch SIDError.TAG_NOT_FOUND {
           packageServiceDelegate!.onPackagingError( SIDError.DATA_PACKAGING_FAILED )
        }
        */
        catch{
            packageServiceDelegate!.onPackagingError( sidError: SIDError.DATA_PACKAGING_FAILED )
        }
        
    }
    
    
    func getPackageInfoJson( sidNetData : SIDNetData ) throws -> PackageInfo? {
       
        let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager
        if( !capturedImagesManager.hasSelfies() ){
            throw SIDError.NO_IMAGE_FOUND
        }
       
        let captureConfig = initCaptureConfig(sidNetData: sidNetData )
        
        let packageInfo = try createCapturedImagesPackageInfo( isMaxFrameTimeout: isMaxFrameTimeout(), captureConfig : captureConfig )
        
      
        return packageInfo
    }
    
    /*
     Save the captured data for later use.
     */
    func saveCapturedData( tag : String,
                           sidNetData : SIDNetData ) throws {
         
        let jsMetaData = readMetadata()
        
        let capturedImagesManager = SmileIDSingleton.sharedInstance.capturedImagesManager
        try checkMetaDataValid( tag: tag, capturedImagesManager: capturedImagesManager, jsMetaData: jsMetaData )
        var metaData : MetaData?
        if( jsMetaData == nil ){
            metaData = MetaData()
            let packageInfo = createPackageInfo(tag: tag, sidNetData: sidNetData)
            if( packageInfo != nil ){
                metaData!.packageInfo = packageInfo
            }
        }
        else{
            metaData = MetaData().fromJsonString(jsonString: jsMetaData! )
            if( metaData?.packageInfo == nil ){
                 metaData?.packageInfo = createPackageInfo(tag: tag, sidNetData: sidNetData)
            }
            else if( metaData?.packageInfo?.referenceId == "" ){
                // packageInfo is not nil, but it is uninitialized
                metaData?.packageInfo = createPackageInfo(tag: tag, sidNetData: sidNetData)
            }
        }
        
        writeMetaData( metaData: metaData! )
  
     
        
  
        
    }
    
    func createPackageInfo( tag : String, sidNetData : SIDNetData )  -> PackageInfo? {
        var packageInfo : PackageInfo?
        do{
            clearMetadata();
           
            let captureConfig = initCaptureConfig(sidNetData: sidNetData );
            
            packageInfo = try createCapturedImagesPackageInfo( isMaxFrameTimeout: isMaxFrameTimeout(), captureConfig : captureConfig )
            
            
        }
        catch {
            print( "CreatePackageInfo : An error occurred ")
            packageServiceDelegate?.onPackagingError(sidError: SIDError.DATA_PACKAGING_FAILED )
        }
        
        return packageInfo
    }
    
    
    func checkMetaDataValid( tag : String,
                             capturedImagesManager : CapturedImagesManager?,
                             jsMetaData : String?
                             ) throws {
        if( capturedImagesManager == nil && jsMetaData == nil ){
            clearMetadata();
            deleteMetaFolder(referenceId: SIDReferenceId.DEFAULT_REFERENCE_ID + tag)
            throw SIDError.TAG_NOT_FOUND
        }
        
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
        let siFileManager = SIFileManager()
        
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
        packageInfo.fullFrameInfoList = fullFrameInfoArr
        packageInfo.frameInfoPreviewFull = fullFrameInfoPreview
        packageInfo.frameInfoIDCard = fullFrameInfoIDCard
        packageInfo.captureConfig = captureConfig
        packageInfo.isMaxFrameTimeout = isMaxFrameTimeout

            
        return packageInfo
            
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

