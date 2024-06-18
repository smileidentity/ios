import SmileID
import SwiftUI

struct JobListItem: View {
    var job: JobData
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(SmileID.theme.backgroundLightest)

            HStack(alignment: .top, spacing: 0) {
                Image(job.jobType.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .clipped()
                VStack(alignment: .leading, spacing: 0) {
                    Group {
                        Text(job.timestamp)
                            .font(.footnote)
                        Text(job.jobType.label)
                        if let resultText = job.resultText {
                            Text(resultText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.leading, 10)

                    if isExpanded {
                        Text("User ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 10)
                            .padding(.leading, 10)
                        Text(job.userId)
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .enableTextSelection(job.userId)
                        Text("Job ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 10)
                            .padding(.leading, 10)
                        Text(job.jobId)
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .enableTextSelection(job.jobId)

                        Group {
                            if let smileJobId = job.smileJobId {
                                Text("Smile Job ID")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.top, 10)
                                Text(smileJobId)
                                    .font(.footnote)
                                    .padding(.vertical, 5)
                            }
                            if let resultCode = job.resultCode {
                                Text("Result Code")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.top, 10)
                                Text(resultCode)
                                    .font(.footnote)
                                    .padding(.vertical, 5)
                            }
                            if let code = job.code {
                                Text("Code")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.top, 10)
                                Text(code)
                                    .font(.footnote)
                                    .padding(.vertical, 5)
                            }
                        }
                        .padding(.leading, 10)
                    }
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
            }
            .padding(.vertical)
            .padding(.horizontal, 10)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
}

#Preview {
    JobsView()
}
