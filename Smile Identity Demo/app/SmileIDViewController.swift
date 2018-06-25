//
//  SmileIDViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 4/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit

class SmileIDViewController: UIViewController {
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        /* TODO
                Check permissions,
                init GeoInfo
            */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Nothing is passed through for the SIDAuthUsingSavedDataSegue
        // print( "segue.identifier = ", segue.identifier )
        if( segue.identifier == "SIDAuthUsingSavedDataSegue" ){
            
            let uploadResultViewController = segue.destination as! UploadResultViewController
            uploadResultViewController.isEnrollMode = false
            uploadResultViewController.use258 = false
            
            // has id is only used when the uploadResultController is used for enroll
            uploadResultViewController.hasId = false
        }
        else {
 
            
            let selfieViewController = segue.destination as! SelfieViewController
            var isEnrollMode : Bool = false;
            var hasId : Bool = false;
            var use258 : Bool = false;
            
            if( segue.identifier == "SIDEnrollSegue" ) {
                isEnrollMode = true;
                hasId = true;
                use258 = false;
            }
            else if( segue.identifier == "SIDEnrollNoIDSegue" ){
                isEnrollMode = true;
                hasId = false;
                use258 = false;
            }
            else if( segue.identifier == "SIDAuthSegue" ){
                isEnrollMode = false;
                hasId = true;
                use258 = false;
            }
            else if( segue.identifier == "SIDAuth258Segue" ){
                isEnrollMode = false;
                hasId = false;
                use258 = true;
            }
            selfieViewController.isEnrollMode = isEnrollMode;
            selfieViewController.hasId = hasId;
            selfieViewController.use258 = use258;
        }
    }
    
    
 

}
