import Foundation

class DataStoreClient {

    let viewContext = CoreDataManager.shared.container.viewContext

    func fetchJobs(
        partnerId: String,
        isProduction: Bool
    ) throws -> [JobData] {
        do {
            let predicate = NSPredicate(
                format: "partnerId == %@ AND isProduction == %@",
                partnerId, NSNumber(value: isProduction)
            )
            let timestampSortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
            let objects = try Job.fetchJobs(
                predicate: predicate,
                sortDescriptors: [timestampSortDescriptor],
                using: viewContext
            )
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

    func updateJob(data: JobData) throws -> JobData? {
        do {
            let updatedObject = try Job.updateJob(data, using: viewContext)
            return JobData(managedObject: updatedObject)
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
