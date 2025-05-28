protocol MetadataProtocol {
    var provides: [MetadataKey] { get set }
    func collectMetadata() -> [Metadatum]
    func addMetadata(forKey: MetadataKey)
    func removeMetadata(forKey: MetadataKey)
    func onStart()
    func onStop()
}
