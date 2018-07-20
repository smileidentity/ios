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

    @IBOutlet weak var lblAlert: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lblResult: UILabel!
    @IBOutlet weak var lblConfidenceLevel: UILabel!
    
    static let MAX_RETRY_TIMEOUT_SEC : Int = 15
    
    @IBAction func onClickUploadNowButton(_ sender: Any) {
        // check if network is available then start the upload
        do {
            let sidNetworkUtils = SIDNetworkUtils()
            if( sidNetworkUtils.isConnected() ){
                startActivityIndicator()
                let sidConfig = createConfig()
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
    
    var geoInfos           : GeoInfos?

    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        lblAlert.text = ""
        stopActivityIndicator()
        
        // TEST
        /*
        let sidResponse = SIDResponse( partnerParams:PartnerParams(),
                                       success: true,
                                       confidenceValue: 1.0 )
        onEnrolled( sidResponse: sidResponse )
         */
        
  
    }
    
    func createConfig() -> SIDConfig {
        
        let sidConfig = SIDConfig()
        
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
        
        if( isEnrollMode ){
            sidConfig.isEnrollMode = true
            sidConfig.useIdCard = hasId
        }
        else{
            sidConfig.isEnrollMode = false
            sidConfig.jobType = 258
        }
        
        sidConfig.build(tag: SmileIDSingleton.USER_TAG)
        
        
        return sidConfig
    }
   
    
    func getRetryOnFailurePolicy() -> RetryOnFailurePolicy {
        let options = RetryOnFailurePolicy();
        options.maxRetryTimeoutSec = UploadResultViewController.MAX_RETRY_TIMEOUT_SEC
        return options;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showToast(
                    msg         : String ){
 
        lblAlert.text = msg
    

        _ = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(hideToast), userInfo: nil, repeats: false)
        
    }
    
    @objc func hideToast(){
          lblAlert.text = ""
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
        if( isEnrollMode ){
            showToast( msg: "Job Complete" )
        }
    }
    
    
    func onError(sidError: SIDError) {
        stopActivityIndicator()
        showToast( msg: sidError.message )
    }
    
    
    func updateUI( resultText : String, confidenceText : String, color : UIColor ) {
        stopActivityIndicator()
        lblResult.textColor = color
        lblResult.text = resultText
        lblConfidenceLevel.text = "Confidence value " + confidenceText + "%"
    }
    
    func onAuthenticated( sidResponse : SIDResponse ) {
    
        var resultText : String?
        var confidenceText : String?
        var color : UIColor?
        
        confidenceText = String( sidResponse.confidenceValue! )
        if( sidResponse.success )!{
            color = UIColor.green
            resultText = "VERIFIED"
        }
        else{
            color = UIColor.red
            resultText = "NOT VERIFIED"
        }
        updateUI(resultText: resultText!, confidenceText: confidenceText!, color: color! )
  
    }
    
    func onEnrolled( sidResponse : SIDResponse ) {
        var resultText : String?

        var color : UIColor?
        let confidenceText = String( sidResponse.confidenceValue! )
        
        if( sidResponse.success )!{
            color = UIColor.green
            resultText = "ENROLLED SUCCESSFULLY"
        }
        else{
            color = UIColor.red
            resultText = "ENROLL FAILED"
        }
        updateUI(resultText: resultText!, confidenceText: confidenceText, color : color! )
        
        
        
        // TEST
        showToast( msg: "TEST" )
        
        
    }
    
    // Android code does not do anything in these functions.
    func onStartJobStatus() {}
    func onEndJobStatus() {}
    func onUpdateJobProgress( progress : Int ) {}
    func onUpdateJobStatus( msg : String ) {
        print( msg )
    }
 
}
