//
//  CameraViewController.swift
//  
//
//  Created by Jubril Olambiwonnu on 12/01/2023.
//

import UIKit
import Vision
import AVFoundation

class PreviewView: UIViewController {

    var layedOutSubviews = false
    var previewLayer: AVCaptureVideoPreviewLayer?
    private let cameraManager = CameraManager.shared
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if layedOutSubviews == false {
            configurePreviewLayer()
            layedOutSubviews = true
        }
    }
    
    func configurePreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        previewLayer?.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer!)
    }
}

extension PreviewView: FaceDetectorDelegate {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
      guard let previewLayer = previewLayer else {
        return CGRect.zero
      }
        let t = CGAffineTransform(translationX: 0.5, y: 0.5)
                    .rotated(by: CGFloat.pi / 2)
                    .translatedBy(x: -0.5, y: -0.5)
                    .translatedBy(x: 1.0, y: 0)
                    .scaledBy(x: -1, y: 1)
        let box = rect.applying(t)
      return previewLayer.layerRectConverted(fromMetadataOutputRect: box)
    }
}


