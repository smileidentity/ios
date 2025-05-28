protocol MetadataProtocol {
    func collectMetadata() -> [Metadatum]
    func onStart()
    func onStop()
}
