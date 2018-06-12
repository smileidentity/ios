//
//  DateTimeUtils.swift
//  Smile Identity Demo
//
//  Created by Janet Brumbaugh on 5/9/18.
//  Copyright © 2018 Smile Identity. All rights reserved.
//

import Foundation

class DateTimeUtils {
    
    func getCurrentDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSS"
        let date = Date()
        let dateString = formatter.string(from: date)

        return dateString
    }
}
