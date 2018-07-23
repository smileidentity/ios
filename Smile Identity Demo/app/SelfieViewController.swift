///
//  SelfieViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 4/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit
import AVFoundation

class SelfieViewController: UIViewController,
    CaptureSelfieDelegate

{
   
    @IBOutlet weak var testImageView: UIImageView!
    @IBOutlet weak var lblPrompt: UILabel!
    @IBOutlet weak var previewView: VideoPreviewView!
    
    var isEnrollMode : Bool?
    var hasId : Bool?
    var use258 : Bool?
    
    var captureSelfie           : CaptureSelfie?
    var logger                  : SILog = SILog()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
         
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSelfie = CaptureSelfie()
        captureSelfie?.setup(captureSelfieDelegate: self,
                             lblPrompt: lblPrompt,
                             previewView: previewView)
 
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /* Do position calcuations in viewDidAppear because the ui is
         layed out and the dimensions have been calculated for the
         device. In viewWillAppear the dimenisions have not
         been calculated for the device yet.
         */
        captureSelfie?.start( screenRect: self.view.bounds )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // captureSelfie?.stop()
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        logger.SIPrint( logOutput: "SelfieView Controller prepare for segue" )

        /* SelfieToCardIDSegue and SelfieToEnrollResultSegue */
        if( segue.identifier == "SelfieToAuthResultSegue" ) {
            let uploadResultViewController = segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = false
            uploadResultViewController.use258 = use258!;
            // hasId is not used with authMode
         }
        else if ( segue.identifier == "SelfieToEnrollResultSegue" ){
            // Enroll mode
            let uploadResultViewController =
                segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = true
            // use258 is not used with enroll mode
            uploadResultViewController.hasId = hasId!
             

        }

        
        // The only other segue is to the card id controller,
        // so no values are passed through in this case.
        
    }
    
    /*
        Capture Selfie Delegate callbacks
    */
    /*
    func onTestDisplayImage( uiImage : UIImage ){
        DispatchQueue.main.async {
            self.view.bringSubview(toFront: self.testImageView)
            self.testImageView.image = uiImage
        }
    }
    */
    
    func onError( sidError : SIDError ){
        let toastUtils = ToastUtils()
        toastUtils.showToast(view: self.view, message: sidError.message )
  
    }

    
    func onComplete( previewUIImage: UIImage) {
         // self.performSegue(withIdentifier: "SelfieToCardIDSegue", sender: self)
        
        let audioUtils = AudioUtils()
        audioUtils.playSound()
        
        if( isEnrollMode )!{
             startEnrollMode();
        }
        else{
            self.performSegue(
                withIdentifier: "SelfieToAuthResultSegue",
                sender: self)
        }
    }
    
    
    func startEnrollMode() {
        if( hasId )!{
            // Go to ID Card
            // mHasId is not passed through in Android
            self.performSegue(
                withIdentifier: "SelfieToIDCardSegue",
                sender: self)
        }
        else{
            // Go to Enroll Result
            /* mHasId is not passed through in Android, since it is false.  EnrollResult has a member var mHasId, which is initialized to false.
             */
            
            self.performSegue(
                withIdentifier: "SelfieToEnrollResultSegue",
                sender: self)
            
        }
    }
    
   
    
 
    
  
  
 
    

 
}
