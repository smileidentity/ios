import SmileID
import SwiftUI

struct JobsView: View {

    var body: some View {
        NavigationView {
            let scrollView = ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        JobListItem(job: .documentVerification)
                    }
                    Spacer()
                }
            }
            .background(SmileID.theme.backgroundLight.ignoresSafeArea())
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItem {
                    Button(action: {}, label: {
                        Image(systemName: "trash.fill")
                    })
                    .buttonStyle(.plain)
                }
            }

            if #available(iOS 16.0, *) {
                scrollView.toolbarBackground(SmileID.theme.backgroundLight, for: .navigationBar)
            } else {
                scrollView
            }
        }
    }
}

#Preview {
    JobsView()
}
