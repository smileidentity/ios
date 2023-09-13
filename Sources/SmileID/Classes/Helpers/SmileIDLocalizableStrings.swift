import Foundation

/// Encapsulates the bundle and tablename of the Localizeable.strings file to be used within the SDK
public struct SmileIDLocalizableStrings {
    /// The bundle where the localizable string is located
    var bundle: Bundle
    /// The name of the localizable strings file. Do not include the files `.strings` extension
    var tablename: String
}
