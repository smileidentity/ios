//
//  ImageProcessingCaps.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/12/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class ImageProcessingCaps {
    
    static let KEY_DEBUG_AFTER_CROP         : String = "debug_rotate_after_crop"
    static let KEY_DETECT_BLURRY_IMAGE      : String = "detectBlurryImage"
    static let KEY_DETECT_LOW_LIGHT         : String = "detectLowLight"
    static let KEY_ROTATE_IMAGES            : String = "rotate_images"
    
    var detectBlurryImage   : Bool = false
    var detectLowLight      : Bool = false
    var debug_rotate_after_crop: Bool = true
    var rotate_images       : Bool = true
    

    func toJsonDict() -> Dictionary<String,Any> {
        // Build a dictionary,
        // then convert it to a formatted json string
        var dict = [String: Any]()
        dict[ImageProcessingCaps.KEY_DEBUG_AFTER_CROP] = debug_rotate_after_crop
        dict[ImageProcessingCaps.KEY_DETECT_BLURRY_IMAGE] = detectBlurryImage
        dict[ImageProcessingCaps.KEY_DETECT_LOW_LIGHT] = detectLowLight
        dict[ImageProcessingCaps.KEY_ROTATE_IMAGES] = rotate_images
        
        return dict
    }
}
