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
        let fetchRequest = Job.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        do {
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
        job.userId = data.userId
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

    static func updateJobStatus(
        _ jobId: String,
        jobSuccess: Bool,
        using context: NSManagedObjectContext
    ) throws {
        let fetchRequest = Job.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "jobId == %@", jobId)
        fetchRequest.fetchLimit = 1
        do {
            guard let job = try context.fetch(fetchRequest).first else {
                throw DataStoreError.fetchError
            }
            job.jobSuccess = jobSuccess
            try context.save()
        } catch {
            throw DataStoreError.updateError
        }
    }

    static func deleteJobs(using context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Job.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(batchDeleteRequest)
        } catch {
            throw DataStoreError.batchDeleteError
        }
    }
}
