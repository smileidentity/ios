//
//  ViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 4/24/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear( animated )
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        
        
        // TEST
        let test = Test()
        test.test()
 
         
     
        
        
        
        
        
   
    }
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

