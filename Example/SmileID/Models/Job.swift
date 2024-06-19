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
    
    static func createWith(data: JobData, using context: NSManagedObjectContext) {
        let job = Job(context: context)
        job.jobId = data.jobId
        job.jobType = Int16(data.jobType.rawValue)
        job.timestamp = data.timestamp
        job.jobComplete = data.jobComplete
        job.jobSuccess = data.jobSuccess
        job.code = data.code
        job.resultCode = data.resultCode
        job.smileJobId = data.smileJobId
        job.resultText = data.resultText
        job.selfieImageUrl = data.selfieImageUrl
        
        do {
            try context.save()
        } catch {
            let error = error as NSError
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
}
