import SwiftUI
import SmileID

struct CountryListView: View {
    @ObservedObject var viewModel = CountryListViewModel()
    @EnvironmentObject var router: Router<NavigationDestination>
    @State private var searchText: String = ""

    var filteredCountries: [ValidDocument] {
        viewModel.validDocuments.filter { document in
            searchText.isEmpty || document.country.name.localizedCaseInsensitiveContains(searchText)
        }
    }


    init() {
        viewModel.getValidDocuments()
    }

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $searchText)
                    .autocapitalization(.none)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding([.horizontal, .top])
            if viewModel.isLoading {
                ActivityIndicator(isAnimating: viewModel.isLoading)
                Spacer()
            } else {
                List(filteredCountries) { validDocument in
                    CountryRow(document: validDocument, action: { document in
                        router.push(.documentSelectorScreen(document: document))
                    })
                }
            }
        }
        .padding(.top, 50)
        .overlay(NavigationBar(backButtonHandler: {router.dismiss()}, title: "Select Country of Issue"))
    }
}

struct CountryListView_Previews: PreviewProvider {
    static var previews: some View {
        CountryListView()
    }
}
