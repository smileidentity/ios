import Foundation

enum ModelError {
  case modelNotLoaded
  case modelLoadFailed(underlying: Error)
  case inferenceError(underlying: Error)
  case invalidInput(String)
  case unsupportedConfiguration
  case memoryPressure
}
