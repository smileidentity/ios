import CoreData
import Foundation

class CoreDataManager {
  static let shared = CoreDataManager()

  static let preview: CoreDataManager = {
    var result = CoreDataManager(inMemory: true)
    let viewContext = result.container.viewContext
    // If we need to add some dummy data for preview content
    do {
      try viewContext.save()
    } catch {
      let error = error as NSError
      fatalError("Unresolved error \(error), \(error.userInfo)")
    }
    return result
  }()

  lazy var container: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "SmileID")

    guard let description = container.persistentStoreDescriptions.first else {
      fatalError("Failed to retrieve a persistent store description.")
    }

    if inMemory {
      description.url = URL(fileURLWithPath: "/dev/null")
    }

    container.loadPersistentStores { _, error in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.name = "viewContext"
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    container.viewContext.undoManager = nil
    container.viewContext.shouldDeleteInaccessibleFaults = true

    return container
  }()

  private let inMemory: Bool
  private init(inMemory: Bool = false) {
    self.inMemory = inMemory
  }
}
