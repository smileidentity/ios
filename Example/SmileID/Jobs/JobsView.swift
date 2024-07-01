import SmileID
import SwiftUI

struct JobsView: View {
    @StateObject var viewModel = JobsViewModel()

    var body: some View {
        NavigationView {
            let scrollView = ScrollView {
                if viewModel.jobs.isEmpty {
                    EmptyStateView(message: "No jobs found")
                        .padding(.top, 120)
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.jobs) { job in
                            JobListItem(job: job)
                        }
                        Spacer()
                    }
                }
            }
            .background(SmileID.theme.backgroundLight.ignoresSafeArea())
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        viewModel.clearButtonTapped()
                    }, label: {
                        Image(systemName: "trash.fill")
                    })
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                viewModel.fetchJobs()
            }
            .actionSheet(isPresented: $viewModel.showConfirmation, content: {
                ActionSheet(
                    title: Text("Are you sure you want to clear all jobs?"),
                    buttons: [
                        .cancel(),
                        .destructive(Text("Clear Jobs"), action: {
                            viewModel.clearJobs()
                        })
                    ]
                )
            })

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
