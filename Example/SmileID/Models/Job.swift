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

    static func fetchJobs(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        using context: NSManagedObjectContext
    ) throws -> [Job] {
        do {
            let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = sortDescriptors
            let results = try context.fetch(fetchRequest)
            return results
        } catch {
            throw DataStoreError.fetchError
        }
    }

    static func create(
        with data: JobData,
        using context: NSManagedObjectContext
    ) throws {
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
            throw DataStoreError.saveItemError
        }
    }
}
