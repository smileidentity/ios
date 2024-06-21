import Foundation

class JobsProvider {
    
    let viewContext = CoreDataManager.shared.container.viewContext
    
    func fetchJobs() -> [JobData] {
        do {
            let objects = try Job.fetchJobs(using: viewContext)
            return objects.compactMap { JobData(managedObject: $0) }
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    func saveJob(data: JobData) {
        do {
            try Job.create(with: data, using: viewContext)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func clearJobs() {
        do {
            try Job.deleteJobs(using: viewContext)
        } catch {
            print(error.localizedDescription)
        }
    }
}
