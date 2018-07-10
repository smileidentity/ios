//
//  ImageUtils.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/10/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class ImageUtils {
    var logger                  : SILog = SILog()
    
    static let FRAME_WIDTH              = CGFloat( 150.0 )
    static let FRAME_HEIGHT             = CGFloat( 150.0 )
    static let PREVIEW_WIDTH            = CGFloat( 480.0 )
    static let PREVIEW_HEIGHT           = CGFloat( 640.0 )
    static let ID_CARD_WIDTH            = CGFloat( 900.0 )
    
    func getCVImageBufferWidth( pixelBuffer: CVImageBuffer ) -> Int {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        return width
    }
    
    func getCVImageBufferHeight( pixelBuffer: CVImageBuffer ) -> Int {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        return height
    }
    
    func getCGImage(pixelBuffer : CVImageBuffer ) ->CGImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        guard let cgImage = context.makeImage() else {
            return nil
        }
        
        return cgImage
        
    }
    
    
    
    /* Get JPGData, no cropping.  Used for the selfie preview.
     Will scale the image to DEFAULT_SCALING_MIN_DIMEN if necessary.
     Currently doScale is unused.
     */
    func getPreviewJPGData( pixelBuffer : CVImageBuffer, doScale : Bool,
                     imageRect : inout CGRect ) -> Data? {
        
        let cgImage = getCGImage(pixelBuffer: pixelBuffer )
    
        
        let uiImage = UIImage( cgImage:cgImage!, scale: 1, orientation:.leftMirrored)
        let heightInPoints = uiImage.size.height
        let heightInPixels = heightInPoints * uiImage.scale
        let widthInPoints = uiImage.size.width
        let widthInPixels = widthInPoints * uiImage.scale
        let aspectRatio = widthInPoints / heightInPoints
 
        let newHeight = ImageUtils.PREVIEW_HEIGHT
        let newWidth = newHeight * aspectRatio

        // check size of image, and scale if necessary
        /*
        if( doScale ){
            uiImage = scaleImage( uiImage: uiImage )
        }
         */
        
        let newUiImage = scaleImage(uiImage: uiImage, newWidth: newWidth, newHeight: newHeight )
        let newHeightInPoints = newUiImage.size.height
        let newHeightInPixels = newHeightInPoints * newUiImage.scale
        
        let newWidthInPoints = newUiImage.size.width
        let newWidthInPixels = newWidthInPoints * newUiImage.scale

        imageRect = CGRect( x:0.0, y:0.0, width:newWidthInPoints, height:newHeightInPoints )
        
        return UIImageJPEGRepresentation( newUiImage, 100.0 )
    }
    
    /*
        ID Card.  Crop to crop rect and compress to jpg
    */
    func getIDCardJPGData( uiImage : UIImage,
        cropRect : CGRect,
        imageRect : inout CGRect ) -> Data? {
        let croppedImage = uiImage.cgImage?.cropping(to: cropRect)
        let uiImage = UIImage( cgImage:croppedImage!, scale: 1, orientation:.leftMirrored)
         let heightInPoints = uiImage.size.height
        let heightInPixels = heightInPoints * uiImage.scale
        let widthInPoints = uiImage.size.width
        let widthInPixels = widthInPoints * uiImage.scale
        let aspectRatio = heightInPoints / widthInPoints
        
        
        let newWidth = ImageUtils.ID_CARD_WIDTH
        let newHeight = newWidth * aspectRatio
        let newUiImage = scaleImage(uiImage: uiImage, newWidth: newWidth, newHeight: newHeight )
        let newHeightInPoints = newUiImage.size.height
        let newHeightInPixels = newHeightInPoints * newUiImage.scale
        
        let newWidthInPoints = newUiImage.size.width
        let newWidthInPixels = newWidthInPoints * newUiImage.scale
        
        imageRect = CGRect( x:0.0, y:0.0, width:newWidthInPoints, height:newHeightInPoints )
        
        return UIImageJPEGRepresentation( newUiImage, 100.0 )

    }
    
    
    /* Get JPGData, with cropping.  Used for rubberband frames */
    func getJPGData( pixelBuffer : CVImageBuffer,
                     faceRect : CGRect,
                     imageRect : inout CGRect ) -> Data? {
        
        
        /* faceRect contains the face.
         crop pixelBuffer with faceRect.
         The resulting image needs to be a square image out
         of the center of the original image in pixelBuffer.
         The dimensions of the square image need to be a
         multiple of 4.
         cropRect is declared 'inout' because we will use it later
         */
        
        
        // Use the larger of width or height
        var half : CGFloat?
        if( faceRect.width > faceRect.height ){
            half = faceRect.width/CGFloat(2.0)
        }
        else{
            half = faceRect.height/CGFloat(2.0)
        }
        // make multiple of FaceDetectorConstants.CROP_FACE_GRAPHIC_MULTIPLE_VALUE)
        half = half!.rounded()
        let newHalf = half! - CGFloat(( Int(half!) % FaceDetectorConstants.CROP_FACE_GRAPHIC_MULTIPLE_VALUE));
        
        let midX = faceRect.origin.x + newHalf
        let midY = faceRect.origin.y + newHalf
        
        // Set the left, right top and bottom of the new crop rect
        let left = midX - newHalf
        let top = midY - newHalf
        
        let cropWidth = newHalf * 2
        let cropHeight = newHalf * 2
        /* Currently cropWidth and cropHeight are ~ 392. */
        
        let cropRect = CGRect( x:left, y:top, width:cropWidth, height:cropHeight )
        
        let cgImage = getCGImage(pixelBuffer: pixelBuffer )
        
        let croppedImage = cgImage?.cropping(to: cropRect)
        
        /* Now that we have a square from the middle of the image, we need
         to scale it so that it is not such a large file.
         We want the resulting image to be about 150x150 px */
        
        // let scale = 150.0/cropWidth
        let scale = CGFloat( 1.0 )
        
        // let scale = CGFloat(1.0)
        print( "cropwidth = " + String( Float(cropWidth )) )
        
        let uiImage = UIImage( cgImage:croppedImage!, scale: scale, orientation:.leftMirrored)
        
        let newUiImage = scaleImage( uiImage: uiImage, newWidth : ImageUtils.FRAME_WIDTH, newHeight : ImageUtils.FRAME_HEIGHT )

        let heightInPoints = newUiImage.size.height
        let heightInPixels = heightInPoints * newUiImage.scale
        
        let widthInPoints = newUiImage.size.width
        let widthInPixels = widthInPoints * newUiImage.scale
        
        imageRect = CGRect( x:0.0, y:0.0, width:widthInPoints, height:heightInPoints )
        
        return UIImageJPEGRepresentation( newUiImage, 100.0 )
        
        /* .leftMirrored makes the uiImage display in the same orientation as the video  preview, which is portrait.
         */
        
        
        
        //let orientation = uiImage.imageOrientation
    }
    

    
    func scaleImage ( uiImage : UIImage, newWidth : CGFloat, newHeight : CGFloat ) -> UIImage {
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        let image = renderer.image { (context) in
            uiImage.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        }
        return image
    }
    
    
    func scaleImage2( uiImage: UIImage ) -> UIImage {
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        
        let origWidth = uiImage.size.width
        let origHeight = uiImage.size.height
        
        var needsScaling : Bool = false
        if( origWidth > CGFloat(CaptureConfig.DEFAULT_SCALING_MIN_DIM ) ||
            origHeight > CGFloat(CaptureConfig.DEFAULT_SCALING_MIN_DIM ) ){
            needsScaling = true
        }
        
        if( !needsScaling ){
            return uiImage
        }
        
        
        // Android code actually downsamples rather than scales the image.
        
        var scaledWidth : CGFloat?
        var scaledHeight : CGFloat?
        var aspectRatio : CGFloat?
        
        if( origWidth > origHeight ){
            aspectRatio = origHeight/origWidth
            scaledWidth = CGFloat(CaptureConfig.DEFAULT_SCALING_MIN_DIM)
            scaledHeight = scaledWidth! * aspectRatio!
        }
        else {
            aspectRatio = origWidth/origHeight
            scaledHeight = CGFloat(CaptureConfig.DEFAULT_SCALING_MIN_DIM)
            scaledWidth = scaledHeight! * aspectRatio!
        }
        
        
        let cgSize = CGSize(width: scaledWidth!, height: scaledHeight!)
        let scaledRect = CGRect(origin: .zero, size:cgSize)
        UIGraphicsBeginImageContextWithOptions(cgSize, !hasAlpha, scale)
        uiImage.draw(in: scaledRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func scaleImageOld( uiImage : UIImage ) -> UIImage? {
        
        let origWidth = uiImage.size.width
        let origHeight = uiImage.size.height
        
        var needsScaling : Bool = false
        if( origWidth > CGFloat(CaptureConfig.DEFAULT_SCALING_MIN_DIM ) ||
            origHeight > CGFloat(CaptureConfig.DEFAULT_SCALING_MIN_DIM ) ){
            needsScaling = true
        }
        
        if( !needsScaling ){
            return uiImage
        }
        
        
        // Android code actually downsamples rather than scales the image.
        
        var scaledWidth : CGFloat?
        var scaledHeight : CGFloat?
        var aspectRatio : CGFloat?
        
        if( origWidth > origHeight ){
            aspectRatio = origHeight/origWidth
            scaledWidth = CGFloat(CaptureConfig.DEFAULT_SCALING_MIN_DIM)
            scaledHeight = scaledWidth! * aspectRatio!
        }
        else {
            aspectRatio = origWidth/origHeight
            scaledHeight = CGFloat(CaptureConfig.DEFAULT_SCALING_MIN_DIM)
            scaledWidth = scaledHeight! * aspectRatio!
        }
        
        
        let scaledRect = CGRect(origin: .zero, size: CGSize(width: scaledWidth!, height: scaledHeight!))
        let imageView = UIImageView(frame: scaledRect )
        imageView.contentMode = .scaleAspectFit
        imageView.image = uiImage
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    
 
    
    
    
    
    
}
