//
//  FPSRange.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 6/11/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class FPSRange{
 
    var fpsRange = [Int]()
    
    init( min : Int, max : Int ){
        self.fpsRange[0] = min
        self.fpsRange[1] = max
    }
}
