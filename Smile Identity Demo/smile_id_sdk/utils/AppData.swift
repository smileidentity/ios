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
    
    
    func getStringSet( key : String ) -> Set<String> {
        let userDefaults = getUserDefaults()
        return userDefaults.object(forKey: key )! as! Set<String>
    }

    
    func setStringSet( key : String, val : Set<String> ) {
        let userDefaults = getUserDefaults()
        userDefaults.set(val, forKey: key)
        userDefaults.synchronize()
    }
    
    
    /* If key does not exist, returns 0. */
    func getInt( _ key : String ) -> Int? {
        return getUserDefaults().integer(forKey: key )
    }
    
    func setInt( _ key : String, val : Int ){
        let userDefaults = getUserDefaults()
        getUserDefaults().set(val, forKey: key )
        userDefaults.synchronize()
    }
    
    /* If the key doesn't exist, returns false */
    func getBool( _ key : String ) -> Bool? {
        return getUserDefaults().bool(forKey: key )
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
    
    func getRefID( defaultRefID : String ) -> String? {
        return getString(KEY_REFERENCE_ID, defaultVal : defaultRefID)
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
    
    func getCountryName( defaultCountryName : String ) -> String? {
        return getString(KEY_COUNTRY_NAME, defaultVal : defaultCountryName)
    }
    
    func setCountryCode( countryCode : String ) {
        setString(KEY_COUNTRY_CODE, val : countryCode);
    }
    
    func getCountryCode( defaultCountryCode : String ) -> String? {
        return getString(KEY_COUNTRY_CODE, defaultVal : defaultCountryCode)
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
    
    func getUserPhoneNumber( defaultUserPhoneNumber : String ) -> String? {
        return getString(KEY_USER_PHONE_NUMBER, defaultVal : defaultUserPhoneNumber)
    }
    
    func setUserName( userName : String ) {
        setString(KEY_USER_NAME, val : userName);
    }
    
    func getUserName( defaultUserName : String ) -> String? {
        return getString(KEY_USER_NAME, defaultVal : defaultUserName)
    }
    
    func setIsVerifyProcess( isVerifyProcess : Bool ) {
        setBool(KEY_IS_VERIFY_PROCESS, val : isVerifyProcess);
    }
    
    func getIsVerifyProcess( defaultIsVerifyProcess : Bool ) -> Bool? {
        return getBool(KEY_IS_VERIFY_PROCESS )
    }

    func setIsEnrollmentCompleted( isEnrollmentCompleted : Bool ) {
        setBool( KEY_IS_ENROLLMENT_COMPLETED, val : isEnrollmentCompleted);
    }
    
    func getIsEnrollmentCompleted( defaultIsEnrollmentCompleted : Bool ) ->
        Bool {
        return getBool(KEY_IS_ENROLLMENT_COMPLETED )!
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
    
    func getFBUserId( defaultFbUserId : String ) -> String? {
        return getString(KEY_FB_USER_ID, defaultVal : defaultFbUserId)
    }
    
    func setFBUserFirstName( fbUserFirstName : String ) {
        setString(KEY_FB_USER_FIRST_NAME, val : fbUserFirstName);
    }
    
    func getFBUserFirstName( defaultFbUserFirstName : String ) -> String? {
        return getString(KEY_FB_USER_FIRST_NAME, defaultVal : defaultFbUserFirstName)
    }
    
    func setFBUserLastName( fbUserLastName : String ) {
        setString(KEY_FB_USER_LAST_NAME, val : fbUserLastName)
    }
    
    func getFBUserLastName( defaultFbUserLastName : String) -> String? {
        return getString(KEY_FB_USER_LAST_NAME, defaultVal : defaultFbUserLastName)
    }
    
    func setFBUserGender( fbUserGender : String ) {
        setString(KEY_FB_USER_GENDER, val : fbUserGender);
    }
    
    
    func setFBUserEmail( fbUserEmail : String) {
        setString(KEY_FB_USER_EMAIL, val : fbUserEmail);
    }
    
    func getFBUserEmail( defaultFbUserEmail : String) -> String? {
        return getString(KEY_FB_USER_EMAIL, defaultVal : defaultFbUserEmail)
    }
    
    func setIsFBLoggedIn( isFbLoggedIn : Bool ) {
        setBool(KEY_IS_FB_LOGGED_IN, val : isFbLoggedIn);
    }
    
    func getIsFBLoggedIn( defaultIsFbLoggedIn : Bool ) -> Bool {
        return getBool(KEY_IS_FB_LOGGED_IN )!
    }

    
    func getFBUserGender( defaultFbUserGender : String ) -> String?{
        return getString(KEY_FB_USER_GENDER, defaultVal :defaultFbUserGender)
    }
    
    
    func setIsOptLoggedIn( isOptLoggedIn : Bool ) {
        setBool( KEY_IS_OPT_LOGGED_IN, val : isOptLoggedIn )
    }
    
    func getIsOptLoggedIn( defaultIsOptLoggedIn : Bool ) -> Bool {
        return getBool( KEY_IS_OPT_LOGGED_IN )!
    }
    
    func setIsIDPresent( isIDPresent : Bool ) {
        setBool( KEY_IS_ID_PRESENT, val : isIDPresent );
    }
    
    func getIsIDPresent( defaultIsIDPresent : Bool ) -> Bool {
        return getBool( KEY_IS_ID_PRESENT )!
    }

    func setIdTaken( idTaken : Bool ) {
        setBool( KEY_ID_TAKEN, val : idTaken);
    }
    
    func isIdTaken() -> Bool {
        return getBool(KEY_ID_TAKEN)!
    }
    
    func removeUserId() {
        remove(KEY_USER_ID)
    }
    
    func removeLastEnrolledJobId() {
        remove(KEY_LAST_ENROLL_JOB_ID)
    }
    
    func isSIFolderCleared() -> Bool {
        return getBool(KEY_SI_FOLDER_CLEARED )!
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
    
    
    func setAuthSmileResponse( response : JsonResponse? ) {
        if( response != nil ){
            setString(KEY_JOB_RESPONSE, val: (response?.getRawJsonString())!)
        }
        else{
            remove(KEY_JOB_RESPONSE)
        }
    }
    
    func getAuthSmileResponse( target : JsonResponse, key : String ) -> JsonResponse?{
        return target.fromJsonString(jsonFormattedString: getString(key,defaultVal: nil)!);
    }
    
    func clearJobResponse() {
        remove(KEY_JOB_RESPONSE)
    }

    
    func getTags() -> Set<String> {
        return getStringSet(key: KEY_TAG_LIST);
    }
    func setTags( tags : Set<String> ) {
        setStringSet( key: KEY_TAG_LIST, val:tags )
    }
    
    func removeTag( tag : String ){
        remove(KEY_USER_TAG);
  
        var tags = getTags()
        tags.remove(tag)
        setTags( tags: tags )
    }
    
    func getCurrentTag( defaultTag : String ) -> String? {
        return getString(KEY_USER_TAG, defaultVal : defaultTag)
    }
    func removeCurrentTag() {
        // remove current tag
        let currentTag = getCurrentTag( defaultTag: SIDReferenceId.NO_TAG )
        remove(KEY_USER_TAG);
        
        // Remove current tag from list
        var tags = getTags()
        tags.remove(currentTag!)
        setTags( tags: tags )
    
    }
    
    func setTag( tag : String ) {
        // update tag
        setString(KEY_USER_TAG, val: tag)
        
        // Add tag to list
        var tags = getTags()
        tags.insert(tag)
        setTags( tags: tags )
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
