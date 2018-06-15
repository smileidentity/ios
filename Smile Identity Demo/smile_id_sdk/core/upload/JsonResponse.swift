//
//  JsonResponse.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

/*
 Base class for AuthSmileResponse, StatusResponse and UploadDataResponse
 */
class JsonResponse {
    
    var rawJsonString   : String = "";
    
    func getRawJsonString() -> String { return rawJsonString }
    func fromJsonString( jsonFormattedString : String ) -> JsonResponse? { return nil }
}

