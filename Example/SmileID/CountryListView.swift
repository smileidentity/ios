import SwiftUI

struct CountryListView: View {
    @State var viewModel: CountryListViewModel
    var body: some View {
        List(viewModel.validDocuments) { validDocument in
            CountryRow(country: validDocument.country.name)
        }
    }
}

struct CountryListView_Previews: PreviewProvider {
    static var previews: some View {
        CountryListView(viewModel: CountryListViewModel())
    }
}
