//
//  Job+CoreDataClass.swift
//  SmileID_Example
//
//  Created by Oluwatobi Omotayo on 18/06/2024.
//  Copyright © 2024 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Job)
class Job: NSManagedObject {
    @NSManaged var jobId: String
    @NSManaged var userId: String
    @NSManaged var jobType: Int16
    @NSManaged var timestamp: String
    @NSManaged var jobComplete: Bool
    @NSManaged var jobSuccess: Bool
    @NSManaged var code: String?
    @NSManaged var resultCode: String?
    @NSManaged var smileJobId: String?
    @NSManaged var resultText: String?
    @NSManaged var selfieImageUrl: String?
}

extension Job {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Job> {
        return NSFetchRequest<Job>(entityName: "Job")
    }
}
