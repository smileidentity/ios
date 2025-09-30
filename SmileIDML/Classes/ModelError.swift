import Foundation

enum ModelError: Error {
  case modelNotLoaded
  case modelLoadFailed(underlying: Error)
  case inferenceError(underlying: Error)
  case invalidInput
  case unsupportedConfiguration
  case memoryPressure
}
