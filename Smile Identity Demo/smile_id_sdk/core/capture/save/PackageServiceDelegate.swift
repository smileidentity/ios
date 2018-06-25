//
//  PackageServiceDelegate.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/25/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

protocol PackageServiceDelegate {
    func onPackagingComplete( packageInfo : PackageInfo,
                             coreRequestData : CoreRequestData )
    func onPackagingError( sidError : SIDError )
}

