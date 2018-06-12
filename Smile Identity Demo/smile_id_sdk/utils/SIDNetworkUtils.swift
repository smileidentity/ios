//
//  SIDNetworkUtils.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/21/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

import SystemConfiguration

class SIDNetworkUtils {
    
    static let CONNECTION_TYPE_OFFLINE  = 0
    static let CONNECTION_TYPE_WIFI     = 1
    static let CONNECTION_TYPE_WWAN     = 2
    
    var connectionType : Int?
  
    func isConnected() -> Bool {
            
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        // return (isReachable && !needsConnection)
        
        let connectionRequired = flags.contains(.connectionRequired)
        let isWWAN = flags.contains(.isWWAN)
        
        if !connectionRequired && isReachable {
            if isWWAN {
                connectionType = SIDNetworkUtils.CONNECTION_TYPE_WWAN
            } else {
                connectionType = SIDNetworkUtils.CONNECTION_TYPE_WIFI
            }
        } else {
            connectionType =  SIDNetworkUtils.CONNECTION_TYPE_OFFLINE
        }
        
        if( connectionType != SIDNetworkUtils.CONNECTION_TYPE_OFFLINE ){
            return true
        }
        else{
            return false
        }
        
    }
        
    
 
}
