//
//  CaptureSelfie.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/8/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CaptureSelfie :
    NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    FaceStateChangedDelegate,
    ProcessFrameDelegate {

    var captureSelfieDelegate : CaptureSelfieDelegate?
    
    var lblPrompt: UILabel?
    var previewView: VideoPreviewView?
    
    
    var session: AVCaptureSession?
    var videoOutput: AVCaptureVideoDataOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // The preview image
    var currentSelfieBytes      : Data?
    
    
    var ovalLayer               : CAShapeLayer?
    var ovalRect                : CGRect?
    var faceDetector            : FaceDetector?
    var previewRect             : CGRect?
    var frameNum                : Int?
    var pictureTaken            : Bool?
    var framesList: [FrameData] = []
    var previewFrame            : FrameData?
    var logger                  : SILog = SILog()
    
     
    func setup( captureSelfieDelegate : CaptureSelfieDelegate,
                lblPrompt : UILabel,
                previewView : VideoPreviewView ){
        
        self.captureSelfieDelegate = captureSelfieDelegate
        self.lblPrompt = lblPrompt
        self.previewView = previewView
        pictureTaken = false
    
        framesList = [FrameData]()
        faceDetector = FaceDetector();
        faceDetector?.setup()
        
        // Setup session
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSession.Preset.photo
        // let device = AVCaptureDevice.default(for: AVMediaType.video)
        guard let device = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .front) else{
                SmileIDSingleton.sharedInstance.selfieCameraExists = false
                print( "No front camera available" )
                captureSelfieDelegate.onError(sidError:
                SIDError.NO_FRONT_FACING_CAMERA_AVAILABLE)
            
            
            
            return
        }
        
        let cmMinTime = device.activeVideoMinFrameDuration
        SmileIDSingleton.sharedInstance.minFPS = Int(1 / ( cmMinTime.value / Int64(cmMinTime.timescale )))
        
        let cmMaxTime = device.activeVideoMaxFrameDuration
        SmileIDSingleton.sharedInstance.maxFPS = Int(1 / ( cmMaxTime.value / Int64(cmMaxTime.timescale )))
       
        SmileIDSingleton.sharedInstance.whiteBalanceMode = device.whiteBalanceMode
        SmileIDSingleton.sharedInstance.selfieCameraExists = true
        
        // Setup input
        var input: AVCaptureDeviceInput!
        var error: NSError?
        
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        // Add input
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            
            // setup output
            videoOutput = AVCaptureVideoDataOutput()
            
            // add output
            if session!.canAddOutput(videoOutput!) {
                
                // Set the pixel format
                
                videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: kCVPixelFormatType_32BGRA]
                
                videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                videoOutput?.connection(with: .video)?.videoOrientation = .portrait
                
                session!.addOutput(videoOutput!)
                
                self.previewView?.session = self.session
                
                // setup live preview
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                self.previewView?.layer.addSublayer(videoPreviewLayer!)
            }
        }
    }
    
    
    func start( screenRect : CGRect ){
        /* Preview frame width is the same as self.view's width.
         Preview frame height uses the aspect ratio, based on the
         width.
         */
        /* Set the video preview frame dimensions */
        let aspectRatio = CGFloat(1.0/0.85)
        let previewWidth = screenRect.width
        let previewHeight = previewWidth * aspectRatio
        let previewX = screenRect.origin.x
        let previewY = CGFloat(0.0)
        /*
         // center vertically
         let yOffset = self.view.bounds.height - previewHeight / 2.0
         let previewY = self.view.bounds.origin.y + yOffset
         */
        previewRect =  CGRect( x:previewX, y:previewY, width:previewWidth, height:previewHeight)
        
        previewView?.bounds = previewRect!
        videoPreviewLayer!.frame = previewRect!
        
        let ovalOverlay = OvalOverlay()
        ovalRect = ovalOverlay.createOvalMask( previewRect: previewRect!, videoPreviewLayer: videoPreviewLayer! )
        
        lblPrompt?.textAlignment = .center
        lblPrompt?.sizeToFit()
        lblPrompt?.translatesAutoresizingMaskIntoConstraints = true
        
        /* start capturing frames */
        frameNum = 0
        session?.startRunning();
    }
    
    
    func stop() {
        if (session?.isRunning)! {
            session?.stopRunning()
        }
    }
    
 
    func processImage(sampleBuffer: CMSampleBuffer) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        if( pixelBuffer != nil ){
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, .readOnly)
            
            /* FaceDetector detectFaces will call the
                onFaceStateChanged, and onProcessFrame delegate callbacks.
            */
            faceDetector?.detectFaces(faceStateChangedDelegate:self,
                                      processFrameDelegate: self,
                                      frameNum:frameNum!,
                                      pixelBuffer: pixelBuffer!,
                                      previewRect: previewRect!,
                                      ovalRect: ovalRect!)
            
           
            
            
        }
    }
    
  
    func captureOutput(_ output: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection){
        print( "captureOutput : dropped frame");
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        /*for kCVPixelFormatType_32BGRA */
        
        DispatchQueue(label: "faceDetection").async {
            self.processImage(sampleBuffer: sampleBuffer);
        }
    }
    
    
    
    
    func onFaceStateChanged( faceState : Int ) {
        // print( "updatePrompt : faceState = ", faceState )
        switch( faceState ){
        case FaceDetectorConstants.DO_MOVE_CLOSER :
            DispatchQueue.main.async {
                self.lblPrompt?.text = "Move Closer"
            }
        case FaceDetectorConstants.CAPTURING :
            DispatchQueue.main.async {
                self.lblPrompt?.text = ""
            }
            
        case FaceDetectorConstants.DO_SMILE :
            DispatchQueue.main.async {
                self.lblPrompt?.text = "Smile"
            }
        default : // FaceDetectorConstants.NO_FACE_FOUND
            DispatchQueue.main.async {
                self.lblPrompt?.text = "Put your face inside Oval"
            }
            
        } // switch
        
    }

   
    /*
     onProcessFrame is called when there is a valid frame with a face.
     The frame is converted to jpg, and the rubberband algorithm is applied.
     This callback is only called if the frame has a face.
    */
    func onProcessFrame( frameState : Int,
                         pixelBuffer : CVImageBuffer,
                         faceRect : CGRect,
                         hasSmile : Bool ){
        logger.SIPrint(logOutput: "onProcessFrame")
        
        switch( frameState ){
            default : // FaceDetectorConstants.FRAME_STATE_CAPTURING
                
                // convert to jpg
                var cropRect = CGRect(x:0,y:0,width:0,height:0)
                let imageUtils = ImageUtils()
                let JPGData = imageUtils.getJPGData(pixelBuffer: pixelBuffer,
                    faceRect:faceRect,
                    cropRect:&cropRect)
                
                 let width = imageUtils.getCVImageBufferWidth( pixelBuffer:pixelBuffer )
                SmileIDSingleton.sharedInstance.devicePortraitHorizontalResolution = width
                let height = imageUtils.getCVImageBufferHeight( pixelBuffer:pixelBuffer )
                SmileIDSingleton.sharedInstance.devicePortraitVerticalResolution = height
                
                /*
                // TEST
                let uiImage = UIImage( data:JPGData! )
                self.captureSelfieDelegate?.onTestDisplayImage(uiImage: uiImage! )
                */
                
                
                if( frameNum! > CaptureConfigConstants.NUM_FRAMES_TO_CAPTURE ){
                    //print( "show smile and take pic" )
                    if( faceDetector?.hasSmile() )!{
                        
                        // Take picture for selfie ui preview,
                        // and also save this frame as the full size preview to send to the server.
                        takePicture( pixelBuffer : pixelBuffer,
                                     responseCode: SmileIDSingleton.SELFIE_RESPONSE_CODE_SUCCESS,
                                        hasSmile:true,
                                        rotation: 0)
                    }
                    else{
                        if( frameNum! > CaptureConfigConstants.MAX_FRAMES ){
                            // Take picture for selfie ui preview,
                            // and also save this frame as the full size preview to send to the server.
                            takePicture( pixelBuffer : pixelBuffer,
                                         responseCode: SmileIDSingleton.SELFIE_RESPONSE_CODE_MAX_FRAME_TIMEOUT,
                                        hasSmile: false,
                                        rotation: 0 )
                        }
                    }
                }
                

                loadRubberBandFrames(frameBytes:JPGData!,
                                     hasSmile:hasSmile,
                                     cropRect: cropRect)
                
            
            
        }
    }
    
  
    
    func loadRubberBandFrames( frameBytes : Data,
                               hasSmile : Bool,
                               cropRect : CGRect ) {
        let exif = 0
        logger.SIPrint(logOutput: "loadRubberBandFrames")
        /* Android supports smile probability.  iOS supports only
            if has smile or not. */
        var smileValue = 0.0
        if( hasSmile ){
            smileValue = 1.0
        }
        
        let dateTimeUtils = DateTimeUtils()
        let formattedDate = dateTimeUtils.getCurrentDateTime();
        
        let left = Int(cropRect.origin.x)
        let top = Int(cropRect.origin.y)
        let width = Int( cropRect.width )
        let height = Int( cropRect.height )
        let right = left + width
        let bottom = top + height
        let frameData = FrameData( frameNum: frameNum!,
                                   frameBytes: frameBytes,
                                   smileValue: smileValue,
                                   dateTime: formattedDate,
                                   left: left,
                                   top: top,
                                   right: right,
                                   bottom: bottom,
                                   width: width,
                                   height: height,
                                   exif: exif)
        // print( "frameData = ", frameData.toString() )
        
        frameNum = frameNum! + 1
        
        if( framesList.count >= CaptureConfigConstants.NUM_FRAMES_TO_CAPTURE){
            let rubberBandUtils = RubberBandUtils()
            let indexToReplace =  rubberBandUtils.getIndexToReplace(
                    framesList: framesList,
                    numImagesToCapture: CaptureConfigConstants.NUM_FRAMES_TO_CAPTURE,
                    frameNum: frameNum!);
            if( indexToReplace != -1 ){
                //print( "CameraSource : frameNum = ", String(frameNum!), " calling RubberBandUtils getIndexToReplace = ", indexToReplace );
                
                framesList[indexToReplace] = frameData
            }

        }
        else{
            framesList.append(frameData)
        }
 
    }
    
    
  
    func takePicture( pixelBuffer : CVImageBuffer,
                      responseCode : Int,
                      hasSmile : Bool,
                      rotation : Int ){
        if( !pictureTaken! ){
            logger.SIPrint( logOutput: "takePicture" )
            pictureTaken = true
            
            var smileValue = 0.0
            if( hasSmile ){
                smileValue = 1.0
            }
            
            let dateTimeUtils = DateTimeUtils()
            let formattedDate = dateTimeUtils.getCurrentDateTime();
            let imageUtils = ImageUtils()
            let width = imageUtils.getCVImageBufferWidth( pixelBuffer:pixelBuffer )
            let height = imageUtils.getCVImageBufferHeight( pixelBuffer:pixelBuffer )
            logger.SIPrint(logOutput: "getJPGData for preview" )
           
            let jpgData = imageUtils.getJPGData(
                pixelBuffer: pixelBuffer,
                doScale: false )
            
            // Save the full size frame to send to the server
            // Note that on Android, it is not compressed to JPG.
            previewFrame = FrameData( frameNum: 0,
                                      frameBytes: jpgData!,
                                      smileValue: smileValue,
                                      dateTime: formattedDate,
                                      left: 0,
                                      top: 0,
                                      right: width,
                                      bottom: height,
                                      width: width,
                                      height: height,
                                      exif: 0)
            
            // TEST
            self.currentSelfieBytes = imageUtils.getJPGData(
                pixelBuffer: pixelBuffer,
                doScale: true )
            
            
            DispatchQueue.main.async {
                // Get the uncropped, scaled jpg from the frame to display in the ui
                // Needs to be done on main thread because of the uiImage scaling
                self.logger.SIPrint(logOutput: "Main thread get currentSelfieBytes" )

                self.logger.SIPrint(logOutput: ("before getcurrentSelfieBytes "))
                self.currentSelfieBytes = imageUtils.getJPGData(
                    pixelBuffer: pixelBuffer,
                    doScale: true )
                self.logger.SIPrint(logOutput: ("after getcurrentSelfieBytes "))
                
                self.logger.SIPrint(logOutput: "calling onComplete")
                self.captureSelfieDelegate?.onComplete( previewUIImage:UIImage( data:self.currentSelfieBytes! )! )
                
                
                /*
                // TEST
                let uiImage = UIImage( data:self.currentSelfieBytes! )
                self.captureSelfieDelegate?.onTestDisplayImage(uiImage: uiImage! )
                 */
                
                
            }
            logger.SIPrint(logOutput: "save Frames")
            
            saveFrames(referenceId: SIDReferenceId.DEFAULT_REFERENCE_ID, responseCode: responseCode, rotation: rotation)
            
            
        }
    }
    
    
    func saveFrames( referenceId : String, responseCode : Int, rotation : Int ) {
        if( framesList.count >= CaptureConfigConstants.NUM_FRAMES_TO_CAPTURE){
            SmileIDSingleton.sharedInstance.selfieImageUI = currentSelfieBytes
            SmileIDSingleton.sharedInstance.framesList = framesList
            SmileIDSingleton.sharedInstance.previewFrame = previewFrame
            
            
            /* TODO start save service
            */
            
            // In Android code, this onComplete causes the caller to
            // call onPause in the activity, which calls camera stop
            // On iOS, we will do it here.
            stop()
            
            startSaveService( referenceId: referenceId, responseCode: responseCode )
            
            logger.SIPrint(logOutput: "end of saveFrames")
            
            
        }
    }
    
    func startSaveService( referenceId : String,
                           responseCode : Int ){
        
        /* TODO - put this in background
        */
        
        let saveSelfieImagesService = SaveSelfieImagesService( referenceId: referenceId, responseCode: responseCode)
        
        saveSelfieImagesService.start()
        
    }
    
    
    
    
    
}
