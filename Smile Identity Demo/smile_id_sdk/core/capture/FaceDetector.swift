//
//  FaceDetector.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/4/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class FaceDetector {
    var faceStateChangedDelegate    : FaceStateChangedDelegate?
    var processFrameDelegate        : ProcessFrameDelegate?
    var bHasFace                    : Bool?
    var bHasSmile                   : Bool?
    
    var currentFaceState            = FaceDetectorConstants.DO_SMILE;
    var previousFaceState           = FaceDetectorConstants.NO_FACE_FOUND;
    var startFrameNumSmile          = 0
    var startFrameNumMoveCloser     = 0
    
    // Change face state after only after consecutiveFrames
    // number of frames
    var consecutiveFrames           = 3
    var frameNum                    : Int?
    var faceDetector                : CIDetector?
    var scaledFaceRect              : CGRect?

    
    func hasFace() -> Bool {
        return self.bHasFace!
    }
    
    func hasSmile() -> Bool {
        return self.bHasSmile!
    }
 
    
    func setup() {
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
    }
    
    
    
    func detectFaces( faceStateChangedDelegate : FaceStateChangedDelegate,
                      processFrameDelegate : ProcessFrameDelegate,
                      
                      frameNum : Int,
                      pixelBuffer:  CVImageBuffer,
                      previewRect : CGRect,
                      ovalRect : CGRect ) {
        

        self.faceStateChangedDelegate = faceStateChangedDelegate
        self.processFrameDelegate = processFrameDelegate
        self.frameNum = frameNum
        
        self.bHasFace = false
        self.bHasSmile = false;
        
        let clapRect =  CVImageBufferGetCleanRect(pixelBuffer)
        let faceImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let faces = faceDetector?.features(in: faceImage, options :[CIDetectorImageOrientation: 5, CIDetectorSmile: true                                               ]) as! [CIFaceFeature]
        
        
        /* Only looking for one face, so use the first one found and break out of the loop.
         Note that Android version of the face detector does not
         use the face detector's results in it's onUpdate method.
         Instead, only Smile Id face detection is used.
         In iOS, we first use the detector's results to see if there is even a face in the first place.
         */
       
        var detectorFace : CIFaceFeature?
        for face in faces {
            detectorFace = face
            bHasFace = true
            // Only using first face found
            break;
        }
        
        if( detectorFace == nil){
            return
        }
        
        if( bHasFace == true ){
            if detectorFace!.hasSmile {
                bHasSmile = true
                // print("Has smile")
            }
            // Check if face is inside the oval
            let faceRect = detectorFace!.bounds
            
            /* The face's bounds uses the cv image space.
             Oval is in ui space, so need to translate.
             */
            
            // Need to also flip preview width and height
            var scaledFaceRect = faceRect
            var temp = scaledFaceRect.size.width;
            scaledFaceRect.size.width = scaledFaceRect.size.height;
            scaledFaceRect.size.height = temp;
            temp = scaledFaceRect.origin.x;
            scaledFaceRect.origin.x = scaledFaceRect.origin.y;
            scaledFaceRect.origin.y = temp;
            
            let widthScaleBy = previewRect.width / clapRect.height;
            let heightScaleBy = previewRect.height / clapRect.width;
            scaledFaceRect.size.width *= widthScaleBy;
            scaledFaceRect.size.height *= heightScaleBy;
            scaledFaceRect.origin.x *= widthScaleBy;
            scaledFaceRect.origin.y *= heightScaleBy;
            
            let faceLeft = scaledFaceRect.origin.x
            let faceRight = faceLeft + scaledFaceRect.width
            let faceTop = faceRect.origin.y
            let faceBottom = faceTop + scaledFaceRect.height
            
            
            /*
             print( "face bounds = faceLeft = ", faceLeft, ", faceRight = ", faceRight, ", faceTop = ", faceTop, ", faceBottom = ", faceBottom )
             
             print( "previewRect = ", previewRect )
             print( "clapRect = ", clapRect )
             print( "scaledFaceRect = ", scaledFaceRect )
             */
            
            
            let leftOk = faceLeft > ovalRect.origin.x + FaceDetectorConstants.FACE_MARGIN
            let rightOk = faceRight < ( ovalRect.origin.x + ovalRect.width ) - FaceDetectorConstants.FACE_MARGIN
            let topOk = faceTop > ( ovalRect.origin.y + FaceDetectorConstants.FACE_MARGIN )
            let bottomOk = faceBottom < ( ovalRect.origin.y + ovalRect.height ) - FaceDetectorConstants.FACE_MARGIN
            
            // print( "leftOk = ", leftOk, ", rightOk = ", rightOk," topOk = ", topOk, ",bottomOk = ", bottomOk )
            
            if( leftOk && rightOk && topOk && bottomOk ) {
                // This frame has a face
                bHasFace = true
                //print( "hasFace" )
                
                /* if the face is too small, then tell the user
                // to move closer.
                */
                
                let faceWidth = scaledFaceRect.width
                let ovalWidth = ovalRect.width
                let moveCloserMargin = ovalWidth * 0.4
                if( faceWidth < ( ovalWidth - moveCloserMargin )){

                    startFrameNumSmile = 0;
                    startFrameNumMoveCloser = startFrameNumMoveCloser + 1;

                     if (startFrameNumMoveCloser >= consecutiveFrames) {
                        //print( "DO_MOVE_CLOSER : consecutiveFrames reached.  Changing state. ")
                        currentFaceState = FaceDetectorConstants.DO_MOVE_CLOSER;
                        faceStateChangedDelegate.onFaceStateChanged(faceState:currentFaceState)
                        
                        startFrameNumMoveCloser = 0
                    }
                } // DO_MOVE_CLOSER
                else if( frameNum >= CaptureConfig.DEFAULT_NUM_IMAGES_TO_CAPTURE ){
                    // last frame.   Tell user to smile, per Android code.
                    print( "Last frame SMILE : frameNum = ", frameNum)
                    currentFaceState = FaceDetectorConstants.DO_SMILE
                    startFrameNumSmile = 0;
                    startFrameNumMoveCloser = 0;
                    faceStateChangedDelegate.onFaceStateChanged(
                        faceState:currentFaceState)
                    
                    // Last frame is captured
                    processFrameDelegate.onProcessFrame(frameState: FaceDetectorConstants.CAPTURING,
                        pixelBuffer : pixelBuffer,
                        faceRect : faceRect,
                        hasSmile : bHasSmile! )
                }
                else{
                    // Capturing
                    currentFaceState = FaceDetectorConstants.CAPTURING
                    faceStateChangedDelegate.onFaceStateChanged(
                        faceState:currentFaceState)
                    
                     processFrameDelegate.onProcessFrame(
                        frameState: FaceDetectorConstants.CAPTURING,
                        pixelBuffer : pixelBuffer,
                        faceRect : faceRect,
                        hasSmile : bHasSmile!)
                }
            }
            else {
                // print( "face detector face found, but face not within oval margins" )
                // No face detected within the oval
                currentFaceState = FaceDetectorConstants.NO_FACE_FOUND;
                faceStateChangedDelegate.onFaceStateChanged(faceState:currentFaceState)
                startFrameNumSmile = 0;
                startFrameNumMoveCloser = 0;
            }

        } // if detectorFaceFound
        else {
            // no detectorFaceFound
            //print( "Face detector No face found" )
            currentFaceState = FaceDetectorConstants.NO_FACE_FOUND;

            faceStateChangedDelegate.onFaceStateChanged(faceState:currentFaceState)
            startFrameNumSmile = 0;
            startFrameNumMoveCloser = 0;
        }
        
        
        
        
    }
  

}
