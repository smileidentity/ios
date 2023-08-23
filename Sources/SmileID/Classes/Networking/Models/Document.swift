import Foundation

public struct Document {
    public var countryCode: String
    public var documentType: String?
    public var aspectRatio: Double

    public init(countryCode: String,
                documentType: String,
                aspectRatio: Double) {
        self.countryCode = countryCode
        self.documentType = documentType
        self.aspectRatio = aspectRatio
    }
}
