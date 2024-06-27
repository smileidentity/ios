import Foundation

struct Metadata: Codable {
    let items: [Metadatum]
    
    init(items: [Metadatum]) {
        self.items = items
    }

    static func `default`(additionalItems: [Metadatum] = []) -> Metadata {
        var defaultItems = [
            Metadatum(name: "sdk", value: "iOS"),
            Metadatum(name: "sdk_version", value: SmileID.version)
        ]
        defaultItems.append(contentsOf: additionalItems)
        return Metadata(items: defaultItems)
    }
}

struct Metadatum: Codable {
    let name: String
    let value: String
}
