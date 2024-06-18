import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SmileID")

        container.loadPersistentStores { _, error in
            if let error {
                // Handle the error appropriately. However, it's useful to use
                // `fatalError(_:file:line:)` during development.
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }

        return container
    }()

    private init() { }
}

extension CoreDataManager {
    func save() {
        guard persistentContainer.viewContext.hasChanges else { return }
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("Failed to save the context:", error.localizedDescription)
        }
    }
    
    /// Creates and configures a private queue context.
    /// - Returns: A new managed object context
    private func newTaskContext() -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        return taskContext
    }
    
    func delete(job: Job) {
        persistentContainer.viewContext.delete(job)
        save()
    }
    
    func deleteJobs(identifiedBy objectIDs: [NSManagedObjectID]) {
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            objectIDs.forEach { objectID in
                let job = viewContext.object(with: objectID)
                viewContext.delete(job)
            }
        }
    }
    
    func addJob(from data: [JobData]) {
        
    }
    
    func updateJobStatus() {
        
    }
    
    func randomDelete(_ jobs: [Job]) {
        let objectIDs = jobs.map { $0.objectID }
        let taskContext = newTaskContext()
        DispatchQueue.global(qos: .background).async {
            taskContext.performAndWait { () -> Void in
                  do {
                      let batchDelete = NSBatchDeleteRequest(objectIDs: objectIDs)
                      try taskContext.execute(batchDelete)
                   }
               }
           }
    }
    
    func deleteJobs(_ jobs: [Job]) throws {
        let objectIDs = jobs.map { $0.objectID }
        let taskContext = newTaskContext()
        
        DispatchQueue.global(qos: .background).async {
            taskContext.perform {
                let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
                guard let fetchResult = try? taskContext.execute(batchDeleteRequest),
                      let batchDeleteResult = fetchResult as? NSBatchDeleteResult,
                      let success = batchDeleteResult.result as? Bool, success else {
                    throw DataStoreError.batchDeleteError
                }
            }
        }
        
//        taskContext.perform {
//            let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
//            guard let fetchResult = try? taskContext.execute(batchDeleteRequest),
//                  let batchDeleteResult = fetchResult as? NSBatchDeleteResult,
//                  let success = batchDeleteResult.result as? Bool, success
//            else {
//                throw DataStoreError.batchDeleteError
//            }
//        }
    }
}
