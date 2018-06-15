//
//  UploadResultViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit

class UploadResultViewController:
    UIViewController,
    SIDNetworkRequestDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblResult: UILabel!
    @IBOutlet weak var lblConfidenceLevel: UILabel!
     
    @IBAction func onClickUploadNowButton(_ sender: Any) {
        // check if network is available then start the upload
        do {
            let sidNetworkUtils = SIDNetworkUtils()
            if( sidNetworkUtils.isConnected() ){
                startActivityIndicator()
                try sidNetworkRequest?.submit( sidConfig: sidConfig )
            }
        }
        catch {
            let logger = SILog()
            logger.SIPrint(logOutput: "UploadResultViewController : An error occurred while trying to upload" )
        }
    }
    
    
    @IBOutlet weak var toastView: UIView!
    
    @IBOutlet weak var lblToast: UILabel!
    
    // Set to true for enroll mode.
    // Set to false for auth mode
    var isEnrollMode : Bool = false;
    
    // mUse258 is used for auth mode
    var use258 : Bool = false;
    
    // mHasId is used for enroll mode
    var hasId  : Bool = false;
    
    var sidNetworkRequest : SIDNetworkRequest?
    
    var sidConfig = SIDConfig()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.viewDidLoad()
        toastView.isHidden = true
        stopActivityIndicator()
        sidNetworkRequest = SIDNetworkRequest()
        sidNetworkRequest?.setDelegate(delegate: self)
        sidNetworkRequest?.initialize()
        
        
        let sidNetData = SIDNetData();
        sidNetData.authUrl = SIDNetUrl.AUTH_URL
        sidNetData.partnerUrl = SIDNetUrl.PARTNER_URL
        sidNetData.partnerPort = SIDNetUrl.PARTNER_PORT
        sidNetData.lambdaUrl = SIDNetUrl.LAMBDA_URL
        sidNetData.jobStatusUrl = SIDNetUrl.JOB_STATUS_URL
        sidNetData.sidAddress = SIDNetUrl.SID_ADDRESS
        sidNetData.sidPort = SIDNetUrl.SID_PORT
        sidConfig.sidNetworkRequest = SIDNetworkRequest()
        sidConfig.sidNetData = sidNetData
        sidConfig.retryOnFailurePolicy = getRetryOnFailurePolicy()
        
        // TODO - make geoinfos be a singleton, and update geolocation dynamically
        // note that geoinfos is not used from sidconfig in the android code.
        // it is recreated in
        if( isEnrollMode ){
            sidConfig.isEnrollMode = true
            sidConfig.useIdCard = hasId
        }
        else{
            sidConfig.isEnrollMode = false
            sidConfig.jobType = 258
        }
        
        sidConfig.build(tag: SmileIDSingleton.USER_TAG)

    }
    
    
   
    
    func getRetryOnFailurePolicy() -> RetryOnFailurePolicy {
        let options = RetryOnFailurePolicy();
        options.maxRetryTimeoutSec = 15
        return options;
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func showToast( toastView   : UIView,
                    toastMsg    : UILabel,
                    msg         : String ){
        toastView.isHidden = false
        toastMsg.text = msg
        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(hideToast), userInfo: nil, repeats: false)
        
    }
    
    @objc func hideToast(){
        toastView?.isHidden = true
    }
    
    func startActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
        }
    }
    
    func stopActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
        }
        
    }
    
    /*
     SIDNetworkRequestDelegate calls
     */
    func onComplete() {
        stopActivityIndicator()
    }
    
    func onError( errMsg : String ){
        stopActivityIndicator()
        
        showToast(toastView: toastView,
                  toastMsg: lblToast,
                  msg: errMsg )
    }
    
    func onUpdate( progress : Int ) {}
    
    func onAuthenticated( response : SIDResponse ) {
        
        var lblResultText : String?
        var lblConfidenceText : String?
        var color : UIColor?
        
        lblConfidenceText = String( response.confidenceValue! )
        if( response.success )!{
            color = UIColor.green
            lblResultText = "VERIFIED"
        }
        else{
            color = UIColor.red
            lblResultText = "NOT VERIFIED"
        }
        updateUI( color: color!, resultText: lblResultText!, confidenceText: lblConfidenceText! )
    }
    
    func onEnrolled( response : SIDResponse ) {
        var lblResultText : String?
        var lblConfidenceText : String?
        var color : UIColor?
        lblConfidenceText = String( response.confidenceValue! )
        
        if( response.success )!{
            color = UIColor.green
            lblResultText = "ENROLLED SUCCESSFULLY"
        }
        else{
            color = UIColor.red
            lblResultText = "ENROLL FAILED"
        }
        updateUI( color: color!, resultText: lblResultText!, confidenceText: lblConfidenceText! )
        
    }
    
    func updateUI( color : UIColor,
                   resultText : String,
                   confidenceText : String ){
        stopActivityIndicator()

        lblResult.textColor = color
        lblResult.text = resultText
        lblConfidenceLevel.text = "Confidence value " + confidenceText + "%"
        
    }
 

}
