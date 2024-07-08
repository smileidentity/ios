import Foundation

class DataStoreClient {

    let viewContext = CoreDataManager.shared.container.viewContext

    func fetchJobs() throws -> [JobData] {
        do {
            let objects = try Job.fetchJobs(using: viewContext)
            return objects.compactMap { JobData(managedObject: $0) }
        } catch {
            throw DataStoreError.fetchError
        }
    }

    func saveJob(data: JobData) throws {
        do {
            try Job.create(with: data, using: viewContext)
        } catch {
            throw DataStoreError.saveItemError
        }
    }
    
    func updateJob(data: JobData, status: Bool) throws -> JobData? {
        do {
            let updateObject = try Job.updateJobStatus(data.jobId, jobSuccess: status, using: viewContext)
            return JobData(managedObject: updateObject)
        } catch {
            throw DataStoreError.updateError
        }
    }

    func clearJobs() throws {
        do {
            try Job.deleteJobs(using: viewContext)
        } catch {
            throw DataStoreError.batchDeleteError
        }
    }
}
