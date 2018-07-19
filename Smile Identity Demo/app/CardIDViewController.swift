//
//  CardIDViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 4/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit
import AVFoundation

class CardIDViewController: UIViewController,
    CaptureIDCardDelegate {

    
    @IBAction func onClickYesButton(_ sender: Any) {
        self.performSegue(withIdentifier: "CardIDToEnrollResultSegue", sender: self)
    }
    @IBAction func onClickNoButton(_ sender: Any) {
        self.view.bringSubview(toFront: previewView)
        captureIDCard?.start()
    }
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var capturedImageContainerView: UIView!
    @IBOutlet weak var previewView: CaptureIDCardVideoPreview!
     
    
    @IBOutlet weak var maskView: UIView!
    var logger                  : SILog = SILog()
    var captureIDCard           : CaptureIDCard?
    
    override func viewDidLoad() {
        super.viewDidLoad()
         logger.SIPrint( logOutput: "id card viewDidLoad" )
     }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        captureIDCard = CaptureIDCard()
        captureIDCard?.setup(captureIDCardDelegate: self,
                             previewView: previewView)
        
        logger.SIPrint( logOutput: "id card top viewWillAppear" )

        self.view.bringSubview(toFront: previewView)
    AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
        
        logger.SIPrint( logOutput: "id card end viewWillAppear" )

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.SIPrint( logOutput: "id card viewDidAppear" )
        
        captureIDCard?.start()
       
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo:
            UIInterfaceOrientation.portrait)
       
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print( "prepare for segue" );
        if( segue.identifier == "CardIDToEnrollResultSegue" ){
            // Enroll mode, so  hasId is true and auth mode is false
            let uploadResultViewController =
                segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = true
            uploadResultViewController.hasId = true;
        }
    }
    
         
    func onComplete( previewUIImage: UIImage) {
        capturedImageView.image = previewUIImage
        self.view.bringSubview(toFront: capturedImageContainerView)
        
    }
        
    func onError( sidError : SIDError ){
    }
    
    
    

}
