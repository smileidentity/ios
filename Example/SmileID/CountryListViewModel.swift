import SmileID
import Combine

class CountryListViewModel: ObservableObject {
    @Published var validDocuments = [ValidDocument]()
    @Published var isLoading = false
    private var subscribers = Set<AnyCancellable>()

    func getValidDocuments() {
        isLoading = true
        let request = ProductsConfigRequest()
        SmileID.api.getValidDocuments(request: request)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {completion in
                self.isLoading = false
                switch completion {
                case .failure(let error):
                    print(error.localizedDescription)
                default:
                    break
                }
            }, receiveValue: { response in
                self.validDocuments = response.validDocuments
            }).store(in: &subscribers)
    }
}
