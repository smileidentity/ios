//
//  SmileIDViewController.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 4/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import UIKit
import MapKit

class SmileIDViewController: UIViewController, CLLocationManagerDelegate {
  
    var locationManager         : CLLocationManager!
    var currentLocation         : CLLocation?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

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
    
    
    
    // Callback for when location changes
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopUpdatingLocation()
        currentLocation = locations[0]
        let appData = AppData()
        // TEST for debugging
        let latitude = (currentLocation?.coordinate.latitude)!
        let longitude = (currentLocation?.coordinate.longitude)!
        let altitude = (currentLocation?.altitude)!
        let time = DateTimeUtils().getCurrentDateTime()
        print( "lat = " + String( latitude ) )
        print( "lng = " + String( longitude ) )
        print( "alt = " +  String( altitude ) )
        print( "time = " + String( time ) )
 

        SmileIDSingleton.sharedInstance.geoInfos = GeoInfos(latitude: latitude, longitude: longitude, altitude: altitude, accuracy: kCLLocationAccuracyBest, lastUpdate: time)
     }
 

}
