//
//  AppData.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/23/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation
import UIKit

class AppData {
    // Store and retrieve data from UserDefaults
    let KEY_JOB_RESPONSE    : String = "com.smileidentity.libsmileid.utils.KEY_JOB_RESPONSE"
    
    let KEY_TAG_LIST            : String = "com.smileidentity.libsmileid.utils.KEY_TAG_LIST"
    
    let JOB_TYPE_AUTH           : Int = 0;
    let JOB_TYPE_ENROLL         : Int =  1;
    
    let KEY_REFERENCE_ID        : String =
        "key_ref_id"
    
    let KEY_USER_TAG            : String =
        "com.smileidentity.libsmileid.utils.KEY_USER_TAG"
    
    let KEY_DEVICE_ID           : String =
        "key_device_id"
    
    let KEY_CLIENT_ID           : String =
        "key_client_id"
    
    let KEY_SELECTED_ID_TYPE    : String =
        "id_type"
    
    let KEY_COUNTRY_NAME        : String =
        "countryName"
    
    let KEY_COUNTRY_CODE        : String =
        "countryCode"
    
    let KEY_USER_LOCATION_COUNTRY   : String =
        "userLocation";
    
    let KEY_USER_ID             : String =
        "user_id"
    
    let KEY_USER_PHONE_NUMBER   : String =
        "userPhoneNumber"
    
    let KEY_USER_NAME           : String =
        "userName"
    
    let KEY_SMILE_CLIENT_ID     : String =
        "smile_client_id"
    
    let KEY_IS_VERIFY_PROCESS   : String =
        "isVerified"
    
    let KEY_LAST_ENROLL_JOB_ID  : String = "last_enroll_job_id"
    
    let KEY_JOB_ID              : String =
        "job_id"
    
    let KEY_FB_USER_ID          : String =
        "fbUserId"
    
    let KEY_FB_USER_LAST_NAME   : String =
        "fbLastName"
    
    let KEY_FB_USER_FIRST_NAME  : String =
        "fbFirstName"
    
    let KEY_FB_USER_GENDER      : String =
        "fbGender"
    
    /* Android port - key says "fbPhoneNo", but it's used for email */
    let KEY_FB_USER_EMAIL       : String =
        "fbPhoneNo"
    
    let KEY_IS_FB_LOGGED_IN     : String =
        "isFbLoggedIn"
    
    let KEY_IS_OPT_LOGGED_IN    : String =
        "isOptLoggedIn"
    
    let KEY_IS_ENROLLMENT_COMPLETED : String = "isEnrollmentCompleted"
    
    let KEY_IS_ID_PRESENT           : String =
        "id_present"
    
    let KEY_SI_FOLDER_CLEARED       : String = "com.smileidentity.libsmileid.utils.KEY_SI_FOLDER_CLEARED"
    
    let KEY_PACKAGE_INFORMATION     : String = "com.smileidentity.libsmileid.utils.KEY_SI_PACKAGE_INFORMATION"
    
    let KEY_ID_TAKEN                : String =  "com.smileidentity.libsmileid.utils.KEY_ID_TAKEN"
     
    func remove ( _ key : String ){
        let userDefaults = getUserDefaults()
        userDefaults.removeObject(forKey: key)
        userDefaults.synchronize()
    }
    
    func clearAll() {
        let userDefaults = getUserDefaults()
        let appDomain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: appDomain)
        userDefaults.synchronize()
    }

    func getString( _ key : String, defaultVal : String? ) -> String? {
        var val : String?
        if let testVal = getUserDefaults().string(forKey: key){
            val = testVal
        } else {
            val = defaultVal
        }
        
        return val
    }
    
    func setString( _ key : String, val : String ){
        let userDefaults = getUserDefaults()
        userDefaults.set(val, forKey: key )
        userDefaults.synchronize()
    }
    
    
    func getStringArr( key : String ) -> Array<String>? {
        let userDefaults = getUserDefaults()
        let stringArr = userDefaults.object(forKey: key )
        if( stringArr == nil ){
            return nil
        }
        else{
            return stringArr! as? Array<String>
        }
    }

    
    func setStringArr( key : String, val : Array<String> ) {
        let userDefaults = getUserDefaults()
        userDefaults.set(val, forKey: key)
        userDefaults.synchronize()
    }
    
    func getInt( key : String, defaultVal : Int ) -> Int {
        let userDefaults = getUserDefaults()
        let tmp = userDefaults.object( forKey: key )
        if( tmp != nil ){
            return userDefaults.integer(forKey: key )
        }
        else{
            return defaultVal
        }
    }
    
    func setInt( _ key : String, val : Int ){
        let userDefaults = getUserDefaults()
        getUserDefaults().set(val, forKey: key )
        userDefaults.synchronize()
    }
    
    
     func getDouble( key : String, defaultVal : Double ) -> Double {
        let userDefaults = getUserDefaults()
        let tmp = userDefaults.object( forKey: key )
        if( tmp != nil ){
            return userDefaults.double( forKey: key )
        }
        else{
            return defaultVal
        }
    }
    
    func setDouble( _ key : String, val : Double ){
        let userDefaults = getUserDefaults()
        getUserDefaults().set(val, forKey: key )
        userDefaults.synchronize()
    }
    

    func getBool( key : String, defaultVal : Bool ) -> Bool {
        let userDefaults = getUserDefaults()
        let tmp = userDefaults.object( forKey: key )
        if( tmp != nil ){
            return userDefaults.bool(forKey: key )
        }
        else{
            return defaultVal
        }
        
    }
    
    func setBool( _ key : String, val : Bool ){
        let userDefaults = getUserDefaults()
        getUserDefaults().set(val, forKey: key )
        userDefaults.synchronize()
    }
    
    func getUserDefaults() -> UserDefaults {
        return UserDefaults.standard
    }
 
    
    func setDeviceID( deviceID : String ) {
        setString(KEY_DEVICE_ID, val: deviceID)
    }
    
    func getDeviceID( defaultVal : String ) -> String? {
        return getString(KEY_DEVICE_ID, defaultVal: defaultVal)
    }
    
    func setClientID( clientID : String ) {
        setString(KEY_CLIENT_ID, val: clientID)
    }
    
    func getClientID( defaultClientID : String ) -> String? {
        return getString(KEY_CLIENT_ID, defaultVal : defaultClientID)
    }
   
    func setRefID( refID : String ) {
        setString( KEY_REFERENCE_ID, val: refID)
    }
    
  
    
    func setSelectedIdType( selectedIdType : String ) {
        setString(KEY_SELECTED_ID_TYPE, val : selectedIdType)
    }
    
    func getSelectedIdType( defaultSelectedIdType : String ) -> String? {
        return getString(KEY_SELECTED_ID_TYPE, defaultVal :  defaultSelectedIdType)
    }

    func setCountryName( countryName : String ) {
        setString(KEY_COUNTRY_NAME, val : countryName);
    }
    
    func getCountryName( defaultCountryName : String ) -> String {
        return getString(KEY_COUNTRY_NAME, defaultVal : defaultCountryName)!
    }
    
    func setCountryCode( countryCode : String ) {
        setString(KEY_COUNTRY_CODE, val : countryCode);
    }
    
    func getCountryCode( defaultCountryCode : String ) -> String {
        return getString(KEY_COUNTRY_CODE, defaultVal : defaultCountryCode)!
    }
    
    func setUserCountryLocation( userCountryLocation : String ) {
        setString(KEY_USER_LOCATION_COUNTRY, val : userCountryLocation);
    }
    
    func getUserCountryLocation( defaultUserCountryLocation : String ) -> String? {
        return getString(KEY_USER_LOCATION_COUNTRY, defaultVal : defaultUserCountryLocation)
    }
    
    func setUserId( userId : String ) {
        setString(KEY_USER_ID, val : userId);
    }
    
    func getUserId( defaultUserId : String ) -> String? {
        return getString(KEY_USER_ID,  defaultVal : defaultUserId)
    }
    
    func setSmileClientId( smileClientId : String ) {
        setString(KEY_SMILE_CLIENT_ID, val : smileClientId);
    }
    
    func getSmileClientId( defaultSmileClientId : String ) -> String? {
        return getString(KEY_SMILE_CLIENT_ID, defaultVal : defaultSmileClientId)
    }
    
    func setUserPhoneNumber( userPhoneNumber : String ) {
        setString(KEY_USER_PHONE_NUMBER, val : userPhoneNumber);
    }
    
    func getUserPhoneNumber( defaultUserPhoneNumber : String ) -> String {
        return getString(KEY_USER_PHONE_NUMBER, defaultVal : defaultUserPhoneNumber)!
    }
    
    func setUserName( userName : String ) {
        setString(KEY_USER_NAME, val : userName);
    }
    
    func getUserName( defaultUserName : String ) -> String {
        return getString(KEY_USER_NAME, defaultVal : defaultUserName)!
    }
    
    func setIsVerifyProcess( isVerifyProcess : Bool ) {
        setBool(KEY_IS_VERIFY_PROCESS, val : isVerifyProcess);
    }
    
    func getIsVerifyProcess( defaultVal : Bool ) -> Bool? {
        return getBool(key: KEY_IS_VERIFY_PROCESS,
                       defaultVal: defaultVal )
    }

    func setIsEnrollmentCompleted( isEnrollmentCompleted : Bool ) {
        setBool( KEY_IS_ENROLLMENT_COMPLETED, val : isEnrollmentCompleted);
    }
    
    func getIsEnrollmentCompleted( defaultVal : Bool ) ->
        Bool {
            return getBool(key: KEY_IS_ENROLLMENT_COMPLETED,
                       defaultVal: defaultVal )
    }

    func setLastEnrollJobId( lastEnrollJobId : String ) {
        setString(KEY_LAST_ENROLL_JOB_ID, val : lastEnrollJobId);
    }
    
    func getLastEnrollJobId( defaultLastEnrollJobId : String ) -> String? {
        return getString(KEY_LAST_ENROLL_JOB_ID, defaultVal : defaultLastEnrollJobId)
    }
    
    func setJobId( jobId: String ) {
        setString(KEY_JOB_ID, val : jobId);
    }
    
    func getJobId( defaultJobId : String ) -> String? {
        return getString(KEY_JOB_ID, defaultVal : defaultJobId)
    }

    /* Facebook related prefs */
    func setFBUserId( fbUserId : String ) {
        setString(KEY_FB_USER_ID, val : fbUserId);
    }
    
    func getFBUserId( defaultFbUserId : String ) -> String {
        return getString(KEY_FB_USER_ID, defaultVal : defaultFbUserId)!
    }
    
    func setFBUserFirstName( fbUserFirstName : String ) {
        setString(KEY_FB_USER_FIRST_NAME, val : fbUserFirstName)
    }
    
    func getFBUserFirstName( defaultFbUserFirstName : String ) -> String {
        return getString(KEY_FB_USER_FIRST_NAME, defaultVal : defaultFbUserFirstName)!
    }
    
    func setFBUserLastName( fbUserLastName : String ) {
        setString(KEY_FB_USER_LAST_NAME, val : fbUserLastName)
    }
    
    func getFBUserLastName( defaultFbUserLastName : String) -> String {
        return getString(KEY_FB_USER_LAST_NAME, defaultVal : defaultFbUserLastName)!
    }
    
    func setFBUserGender( fbUserGender : String ) {
        setString(KEY_FB_USER_GENDER, val : fbUserGender);
    }
    
    
    func setFBUserEmail( fbUserEmail : String) {
        setString(KEY_FB_USER_EMAIL, val : fbUserEmail);
    }
    
    func getFBUserEmail( defaultFbUserEmail : String) -> String {
        return getString(KEY_FB_USER_EMAIL, defaultVal : defaultFbUserEmail)!
    }
    
    func setIsFBLoggedIn( isFbLoggedIn : Bool ) {
        setBool(KEY_IS_FB_LOGGED_IN, val : isFbLoggedIn);
    }
    
    func getIsFBLoggedIn( defaultVal : Bool ) -> Bool {
        return getBool( key: KEY_IS_FB_LOGGED_IN,
                        defaultVal : defaultVal )
    }

    
    func getFBUserGender( defaultVal : String ) -> String{
        return getString( KEY_FB_USER_GENDER,
                          defaultVal : defaultVal )!
    }
    
    
    func setIsOptLoggedIn( isOptLoggedIn : Bool ) {
        setBool( KEY_IS_OPT_LOGGED_IN, val : isOptLoggedIn )
    }
    
    func getIsOptLoggedIn( defaultVal : Bool ) -> Bool {
        return getBool( key: KEY_IS_OPT_LOGGED_IN,
                        defaultVal: defaultVal )
    }
    
    func setIsIDPresent( isIDPresent : Bool ) {
        setBool( KEY_IS_ID_PRESENT, val : isIDPresent );
    }
    
    func getIsIDPresent( defaultVal : Bool ) -> Bool {
        return getBool( key: KEY_IS_ID_PRESENT,
                        defaultVal: defaultVal)
    }

    func setIdTaken( idTaken : Bool ) {
        setBool( KEY_ID_TAKEN, val : idTaken);
    }
    
    func isIdTaken( defaultVal : Bool ) -> Bool {
        return getBool(key: KEY_ID_TAKEN, defaultVal: defaultVal )
    }
    
    func removeUserId() {
        remove(KEY_USER_ID)
    }
    
    func removeLastEnrolledJobId() {
        remove(KEY_LAST_ENROLL_JOB_ID)
    }
    
    func isSIFolderCleared( defaultVal : Bool ) -> Bool {
        return getBool(key : KEY_SI_FOLDER_CLEARED,
        defaultVal: defaultVal )
    }
    
    func setSIFolderCleared( cleared : Bool ){
        setBool(KEY_SI_FOLDER_CLEARED, val : cleared )
    }
    
    func getPackageInformation() -> String? {
        return getString(KEY_PACKAGE_INFORMATION, defaultVal: nil)
    }
    
    func setPackageInformation( packageInformation : String ) {
        setString(KEY_PACKAGE_INFORMATION, val : packageInformation)
    }
    
    
    func setAuthSmileResponse( response : AuthSmileResponse? ) {
        if( response != nil ){
            setString(KEY_JOB_RESPONSE, val: (response?.getRawJsonString())!)
        }
        else{
            remove(KEY_JOB_RESPONSE)
        }
    }
    
 
    
    func getAuthSmileResponse( defaultVal : String? ) -> String? {
        return getString( KEY_JOB_RESPONSE, defaultVal:defaultVal  )
    }
    
    func clearJobResponse() {
        remove(KEY_JOB_RESPONSE)
    }
    func removeJobResponse() {
        remove(KEY_JOB_RESPONSE);
    }
    
 
    
    func getTags() -> Array<String>? {
        return getStringArr(key: KEY_TAG_LIST )
    }
    func setTags( tags : Array<String> ) {
        setStringArr( key: KEY_TAG_LIST, val:tags )
    }
    
    func removeTag( tag : String ){
        remove(KEY_USER_TAG);
  
        var tagsArr = getTags()
        if( tagsArr != nil ){
            
            var tagsSet = Set( tagsArr! )
            
            tagsSet.remove(tag)
            tagsArr = Array(tagsSet)
            setTags( tags: tagsArr! )
            
 
        }
        
    }
    
    func getCurrentTag( defaultTag : String ) -> String? {
        return getString(KEY_USER_TAG, defaultVal : defaultTag)
    }
    func removeCurrentTag() {
        // remove current tag
        let currentTag = getCurrentTag( defaultTag: SIDReferenceId.NO_TAG )
        remove(KEY_USER_TAG);
        
        // Remove current tag from list
        var tagsArr = getTags()
        if( tagsArr != nil ){
            var tagsSet = Set( tagsArr! )
            tagsSet.remove(currentTag!)
            tagsArr = Array(tagsSet)
            setTags( tags: tagsArr! )
        }
    
    }
    
    func setTag( tag : String ) {
        // update tag
        setString(KEY_USER_TAG, val: tag)
        
        // Add tag to list
        var tagsArr = getTags()
        
        
        // Convert to set
        if( tagsArr != nil ){
            // convert to set, to make sure there are no duplicates
            var tagsSet = Set( tagsArr! )
            tagsSet.insert(tag)
            // convert back to array
            tagsArr = Array(tagsSet)
         }
        else {
            tagsArr = Array<String>()
            tagsArr!.append(tag)
        }
        setTags( tags: tagsArr! )
        
    }
    
    // Increase tag no of reference id for next capture process
    func setTag( defaultDeviceID    : String,
                 defaultClientID    : String,
                 defaultTag         : String,
                 defaultReferenceID : String ) {

        let deviceID = getDeviceID(defaultVal: defaultDeviceID)
        let clientID = getClientID(defaultClientID: defaultClientID)
        let tag = getCurrentTag(defaultTag: defaultTag)
        let referenceID = buildReferenceID(deviceID: deviceID!, clientID: clientID!, currentTag: tag!, defaultReferenceID: defaultReferenceID)
        setRefID(refID: referenceID)
        setTag(tag: tag!);
    }
    
    
    func assignTag( tag : String ) {
        setTag(defaultDeviceID: SIDReferenceId.DEFAULT_DEVICE_ID,
               defaultClientID: SIDReferenceId.DEFAULT_CLIENT_ID,
               defaultTag: SIDReferenceId.NO_TAG + tag,
               defaultReferenceID: SIDReferenceId.DEFAULT_REFERENCE_ID);
    }
    
    func assignTag() {
        assignTag(tag: SIDReferenceId.NO_TAG);
    }

    

    
    func createReferenceId( defaultDeviceID : String,
                            defaultClientID : String,
                            defaultTag      : String,
                            defaultReferenceID : String ) -> String {
        let deviceID = getDeviceID(defaultVal: defaultDeviceID);
        let clientID = getClientID(defaultClientID: defaultClientID);
        let currentTag = getCurrentTag( defaultTag : defaultTag);
        
        setTag(tag: currentTag!);
        return buildReferenceID(deviceID: deviceID!, clientID: clientID!, currentTag: currentTag!, defaultReferenceID: defaultReferenceID);
    }
    
    func createReferenceId( tag : String ) -> String {
        return createReferenceId(
            defaultDeviceID: SIDReferenceId.DEFAULT_DEVICE_ID,
            defaultClientID: SIDReferenceId.DEFAULT_CLIENT_ID,
            defaultTag: tag,
            defaultReferenceID: SIDReferenceId.DEFAULT_REFERENCE_ID);
    }
    
    func buildReferenceID( deviceID     : String,
                           clientID     : String,
                           currentTag   : String,
                           defaultReferenceID : String ) -> String {

        // Try to convert to an Int.
        if let nDeviceId = Int(deviceID) {
            if let nClientId = Int( clientID ){
                return String(format: "D%02d_C%03d_T%@",
                       nDeviceId,
                       nClientId,
                       currentTag )
            }
            else{
                return defaultReferenceID
            }
        } else {
            return defaultReferenceID
        }
    }
    
  
}
