import SmileID
import SwiftUI

struct JobsView: View {
    @StateObject var viewModel: JobsViewModel

    var body: some View {
        NavigationView {
            let scrollView = ScrollView {
                if viewModel.jobs.isEmpty {
                    EmptyStateView(message: "No jobs found")
                        .padding(.top, 120)
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.jobs) { job in
                            JobListItem(model: JobItemModel(job: job))
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItem {
                    if !viewModel.jobs.isEmpty {
                        Button(action: {
                            viewModel.clearButtonTapped()
                        }, label: {
                            Image(systemName: "trash.fill")
                        })
                        .buttonStyle(.plain)
                    }
                }
            }
            .onAppear {
                viewModel.fetchJobs()
            }
            .toast(isPresented: $viewModel.showToast) {
                Text(viewModel.toastMessage)
                    .font(SmileID.theme.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .background(SmileID.theme.backgroundLight.ignoresSafeArea())
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
    JobsView(
        viewModel: JobsViewModel(
            config: Config(
                partnerId: "1000",
                authToken: "",
                prodUrl: "",
                testUrl: "",
                prodLambdaUrl: "",
                testLambdaUrl: ""
            )
        )
    )
}
