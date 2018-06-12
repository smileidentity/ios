//
//  SIDError.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

enum SIDError : Error {
    case SUCCESS
    case COULD_NOT_INITIALIZE_CAMERA
    case NO_FRONT_FACING_CAMERA_AVAILABLE
    case ID_CARD_CAPTURE_FAILED
    case ID_CARD_PICTURE_CALLBACK_FAILED
    case ID_CARD_AUTOFOCUS_FAILED
    case ID_CARD_TOUCHFOCUS_FAILED
    case ID_CARD_DRAWVIEW_FAILED
    case ID_CARD_CAMERA_INITIALIZATION_FAILED
    case UNABLE_TO_SUBMIT
    case UNABLE_TO_SUBMIT_PACKAGING_ERROR
    case UNABLE_TO_SUBMIT_COULD_NOT_UPLOAD_ZIP
    case UNABLE_TO_SUBMIT_COULD_NOT_CREATE_ZIP
    case UNABLE_TO_SUBMIT_COULD_NOT_TRANSMIT_TO_LAMBDA
    case UNABLE_TO_SUBMIT_COULD_NOT_AUTH
    case UNABLE_TO_VERIFY
    case REQUEST_FAILED_TRY_AGAIN
    case FAILED_JOB_STATUS_CANCELLED_OR_TIMEOUT_AUTH
    case FAILED_JOB_STATUS_CANCELLED_OR_TIMEOUT
    case PREVIOUS_ENROLL_FAILED
    case DATA_PACKAGING_FAILED
    case ENROLL_FAILED
    case DATA_PACKAGING_FAILED_AUTH_BEFORE_ENROLL
    case NO_IMAGE_FOUND
    case ID_CARD_REQUIRED
    case ENROLL_NOT_FOUND
    case ERROR_UNKNOWN
    case UNABLE_TO_SUBMIT_TRY_AGAIN
    case TAG_NOT_FOUND
    
    case custom(errMsg: String)
    
}

extension SIDError {
    
    var message: String {
        switch self {
       
            case .COULD_NOT_INITIALIZE_CAMERA:
                return NSLocalizedString("error_unable_to_init_capture_selfie", comment: "")
            
        case .NO_FRONT_FACING_CAMERA_AVAILABLE:
             return NSLocalizedString("alert_front_camera_not_supported", comment: "")
            
        case .ID_CARD_CAPTURE_FAILED:
             return NSLocalizedString("id_card_capture_failed", comment: "")
           
        case .ID_CARD_PICTURE_CALLBACK_FAILED:
             return NSLocalizedString("id_card_picture_callback_failed", comment: "")
            
        case .ID_CARD_AUTOFOCUS_FAILED:
             return NSLocalizedString("id_card_autofocus_failed", comment: "")
            
        case .ID_CARD_TOUCHFOCUS_FAILED:
             return NSLocalizedString("id_card_touchfocus_failed", comment: "")
            
        case .ID_CARD_DRAWVIEW_FAILED:
             return NSLocalizedString("id_card_draw_view_failed", comment: "")
            
        case .ID_CARD_CAMERA_INITIALIZATION_FAILED:
             return NSLocalizedString("id_card_camera_initialization_failed", comment: "")
            
        case .UNABLE_TO_SUBMIT:
             return NSLocalizedString("unable_to_submit", comment: "")
            
        case .UNABLE_TO_SUBMIT_PACKAGING_ERROR:
             return NSLocalizedString("unable_to_submit_packaging_error", comment: "")
            
        case .UNABLE_TO_SUBMIT_COULD_NOT_UPLOAD_ZIP:
             return NSLocalizedString("unable_to_submit_could_not_upload_zip", comment: "")
            
        case .UNABLE_TO_SUBMIT_COULD_NOT_CREATE_ZIP:
             return NSLocalizedString("unable_to_submit_could_not_create_zip", comment: "")
            
        case .UNABLE_TO_SUBMIT_COULD_NOT_TRANSMIT_TO_LAMBDA:
             return NSLocalizedString("unable_to_submit_could_not_transmit_to_lambda", comment: "")
            
        case .UNABLE_TO_SUBMIT_COULD_NOT_AUTH:
             return NSLocalizedString("unable_to_submit_could_not_authorize", comment: "")
            
        case .UNABLE_TO_VERIFY:
             return NSLocalizedString("unable_to_verify", comment: "")
            
        case .REQUEST_FAILED_TRY_AGAIN:
             return NSLocalizedString("alert_msg_try_again", comment: "")
            
        case .FAILED_JOB_STATUS_CANCELLED_OR_TIMEOUT_AUTH:
             return NSLocalizedString("label_signup_again", comment: "")
            
        case .FAILED_JOB_STATUS_CANCELLED_OR_TIMEOUT:
             return NSLocalizedString("label_resubmit_again", comment: "")
            
        case .PREVIOUS_ENROLL_FAILED:
             return NSLocalizedString("label_previous_enroll_failed", comment: "")
            
        case .ENROLL_FAILED:
             return NSLocalizedString("enroll_failed", comment: "")
            
        case .DATA_PACKAGING_FAILED:
             return NSLocalizedString("label_packaging_failed", comment: "")
            
        case .DATA_PACKAGING_FAILED_AUTH_BEFORE_ENROLL:
             return NSLocalizedString("authentication_before_enroll", comment: "")
            
        case .NO_IMAGE_FOUND:
             return NSLocalizedString("no_images_found", comment: "")
            
        case .ID_CARD_REQUIRED:
             return NSLocalizedString("job_type_requires_id_card", comment: "")
            
        case .ENROLL_NOT_FOUND:
             return NSLocalizedString("authentication_failed_enroll_not_found", comment: "")
            
        case .UNABLE_TO_SUBMIT_TRY_AGAIN:
             return NSLocalizedString("transmission_failed_try_again", comment: "")
            
        case .TAG_NOT_FOUND:
             return NSLocalizedString("tag_not_found", comment: "")
            
        case .ERROR_UNKNOWN:
             return NSLocalizedString("error_unknown", comment: "")
        /* custom is an example for how usage with a customized error message */
        case .custom(errMsg: let aMsg):
                return aMsg
            
        default : // SUCCESS
                return "success"
       
        }
    }
}

/*
 Usage examples


 COULD_NOT_INITIALIZE_CAMERA.message
 
 throw SIDError.COULD_NOT_INITIALIZE_CAMERA
 throw SIDError.custom("custom error message")

 
 */

