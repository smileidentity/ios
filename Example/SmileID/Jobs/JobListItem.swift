import SmileID
import SwiftUI

struct JobListItem: View {
    var job: JobData
    @State private var isExpanded = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(SmileID.theme.backgroundLightest)

            HStack(alignment: .top) {
                Image(job.jobType.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .clipped()
                VStack(alignment: .leading) {
                    Text(job.timestamp)
                        .font(.footnote)
                    Text(job.jobType.label)
                    if let resultText = job.resultText {
                        Text(resultText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    if isExpanded {
                        Text("User ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 5)
                        Text(job.userId)
                            .font(.footnote)
                        Text("Job ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 5)
                        Text(job.jobId)
                            .font(.footnote)
                        if let smileJobId = job.smileJobId {
                            Text("Smile Job ID")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.top, 5)
                            Text(smileJobId)
                                .font(.footnote)
                        }
                        if let resultCode = job.resultCode {
                            Text("Result Code")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.top, 5)
                            Text(resultCode)
                                .font(.footnote)
                        }
                        if let code = job.code {
                            Text("Code")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.top, 5)
                            Text(code)
                                .font(.footnote)
                        }
                    }
                }
                Spacer()
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical)
            .padding(.horizontal, 10)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
}

#Preview {
    JobsView()
}
