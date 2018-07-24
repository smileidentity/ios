//
//  CaptureIDCard.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/16/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CaptureIDCard :
    NSObject,
    AVCapturePhotoCaptureDelegate,
    IDCardTouchDelegate {
    
    var referenceId : String?
    var captureIDCardDelegate : CaptureIDCardDelegate?
    var handleTouchDelegate : CaptureSelfieDelegate?
    
    
    var previewView : CaptureIDCardVideoPreview?
    
    var session: AVCaptureSession?
    var photoOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var photoSampleBuffer: CMSampleBuffer?
    var previewPhotoSampleBuffer: CMSampleBuffer?
    var idCardOverlay : IDCardOverlay?
    let logger                              = SILog()
    
    func setup( captureIDCardDelegate : CaptureIDCardDelegate,
        previewView : CaptureIDCardVideoPreview ) {
        
        

        self.captureIDCardDelegate = captureIDCardDelegate
        self.previewView = previewView
    self.previewView?.setupTouchRecognizer(idCardTouchDelegate: self)
        
        let appData = AppData()
        referenceId = appData.createReferenceId(tag: SmileIDSingleton.USER_TAG )
        appData.setRefID(refID: referenceId!)
        
        
        
        // Setup session
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSession.Preset.photo
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        
        // Setup input
        var input: AVCaptureDeviceInput!
        var error: NSError?
        
        do {
            input = try AVCaptureDeviceInput(device: backCamera!)
        } catch let error1 as NSError {
            error = error1
            input = nil
           
            logger.SIPrint( logOutput: error!.localizedDescription)
        }
        
        // Add input
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            
            // setup output
            photoOutput = AVCapturePhotoOutput()
            
            // add output
            if session!.canAddOutput(photoOutput!) {
                session!.addOutput(photoOutput!)
                
                self.previewView?.session = self.session
                
                // setup live preview
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight  
                previewView.layer.addSublayer(videoPreviewLayer!)
                
            }
        }
    }
    
    
    func start() {
        /* Preview frame width is the same as self.view's width.
         Preview frame height uses the aspect ratio, based on the
         width.
         */
        
    
        videoPreviewLayer!.frame = (previewView?.bounds)!
        idCardOverlay = IDCardOverlay()
        idCardOverlay?.createRectMask(videoPreviewLayer: videoPreviewLayer!)
        
        session!.startRunning();
        
    }
    
    
    func stop() {
        if (session?.isRunning)! {
            session?.stopRunning()
        }
    }
    
    
 
    
    
    // =========================================================================
    // MARK: - AVCapturePhotoCaptureDelegate
    
    // Monitoring Capture Progress
    func photoOutput(_ output: AVCapturePhotoOutput,
                     willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings){
        //logger.SIPrint( logOutput:"photoOutput : willBeginCaptureFor" );
    }
    
    func photoOutput(_: AVCapturePhotoOutput, willCapturePhotoFor: AVCaptureResolvedPhotoSettings){
        // logger.SIPrint( logOutput:"photoOutput : willCapturePhotoFor" );
    }
    
    func photoOutput(_: AVCapturePhotoOutput, didCapturePhotoFor: AVCaptureResolvedPhotoSettings){
        // logger.SIPrint( logOutput:"photoOutput : didCapturePhotoFor" );
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        // logger.SIPrint( logOutput:"photoOutput : didCapturePhotoFor" );
        guard error == nil else {
           logger.SIPrint( logOutput:"Error capture process: \(error ?? "An error occurred capturing the photo" as! Error)")
            return
        }
    }
    
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        // logger.SIPrint( logOutput:"photoOutput : didFinishProcessingPhoto" );
        // Check if there is any error in capturing
        guard error == nil else {
            logger.SIPrint( logOutput:"Fail to capture photo: \(String(describing: error))")
            return
        }
        
        // Check if the pixel buffer could be converted to image data
        guard let imageData = photo.fileDataRepresentation() else {
            logger.SIPrint( logOutput:"Fail to convert pixel buffer")
            return
        }
        
        // Check if UIImage could be initialized with image data
        guard let uiImageFull = UIImage.init(data: imageData , scale: 1.0) else {
            logger.SIPrint( logOutput:"Fail to convert image data to UIImage")
            return
        }
        
        /*
        // this shows the entire image, scaled into the preview
        // imageView.
        captureIDCardDelegate?.onComplete( previewUIImage: uiImageFull )
        */
        
       
        // translate mask dimensions */
        /*
        logger.SIPrint( logOutput:"uiImage width = ", uiImageFull.size.width )
        logger.SIPrint( logOutput: "uiImage height = ", uiImageFull.size.height )
        logger.SIPrint( logOutput:"preview width = ", previewView!.bounds.width )
        logger.SIPrint( logOutput:"preview height = ", previewView!.bounds.height )
        */
        
        // uiImageFull height is greater than width.
        // which is opposite what the preview is.
        // We are going to scale the uiImage.
        let scaleVert = uiImageFull.size.width / previewView!.bounds.height
        
        let scaleHorz = uiImageFull.size.height / previewView!.bounds.width
        
        // overlay is landscape
        let maskVert = idCardOverlay?.getLeftRightMaskWidth()
        let top = maskVert! * scaleVert
        
        let maskHorz =  idCardOverlay?.getTopBottomMaskWidth()
        let left = maskHorz! * scaleHorz
   
        let maskWidth = idCardOverlay?.getMaskWidth()
        let height = maskWidth! * scaleVert
        
        let maskHeight = idCardOverlay?.getMaskHeight()
        let width = maskHeight! * scaleHorz
        
        // uiimage to crop is portrait so switch
        let cropRect = CGRect( x:left, y:top, width:width, height:height)
        // print( "cropRect = ", cropRect )
        
        let imageUtils = ImageUtils()
        
        // Convert to jpg and save
        var imageRect = CGRect(x:0,y:0,width:0,height:0)
        let jpgData = imageUtils.getIDCardJPGData( uiImage: uiImageFull, cropRect:cropRect, imageRect : &imageRect )
        let croppedUIImage = UIImage(data: jpgData! )
        
        /*
        logger.SIPrint( logOutput:"croppedUIImage width = ", croppedUIImage?.size.width )
        logger.SIPrint( logOutput: "croppedUIImage height = ", croppedUIImage?.size.height )
        */
        captureIDCardDelegate?.onComplete( previewUIImage: croppedUIImage! )
        
        let dateTimeUtils = DateTimeUtils()
        let formattedDate = dateTimeUtils.getCurrentDateTime();
     
        let frameLeft = Int(imageRect.origin.x)
        let frameTop = Int(imageRect.origin.y)
        let frameWidth =  Int( imageRect.width )
        let frameHeight = Int( imageRect.height )
        let frameRight = Int( frameLeft + frameWidth)
        let frameBottom = Int(frameTop + frameHeight)
        
        let idCardFrame = FrameData( frameNum: 0,
                                  frameBytes: jpgData!,
                                  smileValue: 0.0,
                                  dateTime: formattedDate,
                                  left: frameLeft,
                                  top: frameTop,
                                  right: frameRight,
                                  bottom: frameBottom,
                                  width: frameWidth,
                                  height: frameHeight,
                                  exif: 0)

        
        
        let appData = AppData()
        appData.setIdTaken(idTaken: true )
        appData.setIsIDPresent( isIDPresent: true )
        SmileIDSingleton.sharedInstance.idCardFrame = idCardFrame
        startSaveIdCardService(referenceId: referenceId!)
        
        captureIDCardDelegate?.onComplete( previewUIImage: UIImage(data: jpgData! )! )
        
        
        // Stop video capturing session (Freeze preview)
        session?.stopRunning()
        
        previewView?.removeTouchCircle()
    }

    
    
    func onHandleTouch() {
        let photoSettingsJPEG = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
        
        /* this didn't change the output
         if let photoOutputConnection = photoOutput?.connection(with: AVMediaType.video) {
         photoOutputConnection.videoOrientation = AVCaptureVideoOrientation.portrait
         }
         */
        photoOutput?.capturePhoto(with: photoSettingsJPEG, delegate: self)

    }
    
    
    
    func startSaveIdCardService( referenceId : String ){

   
        let saveIdCardImageService = SaveIdCardImageService( referenceId: referenceId )
        
        saveIdCardImageService.start()
    }
    
    
    
    
}
