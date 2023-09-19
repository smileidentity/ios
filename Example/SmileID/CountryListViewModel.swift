import SmileID

class CountryListViewModel {
    var validDocuments = [ValidDocument]()
    
    func getValidDocuments() {
        let request = ProductsConfigRequest()
        SmileID.api.getValidDocuments(request: request)
            .sink(receiveCompletion: {completion in
                switch completion {
                case .failure(let error):
                    print(error.localizedDescription)
                default:
                    break
                }
            }, receiveValue: { response in
                self.validDocuments = response.validDocuments
            })
    }
}
