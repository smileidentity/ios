import Foundation

class FrameSaver<Identifier: Hashable, Frame, MetaData> {
  private let saveFrameQueue = DispatchQueue(label: "com.smileidentity.frameSaver", qos: .userInitiated)
  private var savedFrames: [Identifier: [Frame]] = [:]

  func saveFrame(frame: Frame, metaData: MetaData) {
    saveFrameQueue.sync {
      guard let identifier = getSaveFrameIdentifier(frame: frame, metaData: metaData) else {
        return
      }

      let maxSavedFrames = getMaxSavedFrames(savedFrameIdentifier: identifier)

      if savedFrames[identifier] == nil {
        savedFrames[identifier] = []
      }

      savedFrames[identifier]!.insert(frame, at: 0)

      while savedFrames[identifier]!.count > maxSavedFrames {
        removeFrame(identifier: identifier, frames: &savedFrames[identifier]!)
      }
    }
  }

  func getSavedFrames() -> [Identifier: [Frame]] {
    saveFrameQueue.sync {
      savedFrames
    }
  }

  func reset() {
    saveFrameQueue.sync {
      savedFrames.removeAll()
    }
  }

  func getMaxSavedFrames(savedFrameIdentifier _: Identifier) -> Int {
    fatalError("Must be implemented by subclass")
  }

  func getSaveFrameIdentifier(frame _: Frame, metaData _: MetaData) -> Identifier? {
    fatalError("Must be implemented by subclass")
  }

  func removeFrame(identifier _: Identifier, frames: inout [Frame]) {
    frames.removeLast()
  }
}
