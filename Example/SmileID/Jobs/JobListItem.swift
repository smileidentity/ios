import SmileID
import SwiftUI

struct JobListItem: View {
  @StateObject var model: JobItemModel

  @State private var isExpanded = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .fill(SmileID.theme.backgroundLightest)

      HStack(alignment: .top, spacing: 0) {
        Image(model.job.jobType.icon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 60, height: 60)
          .clipped()
        VStack(alignment: .leading, spacing: 0) {
          Group {
            Text(model.job.timestamp.jobTimestampFormat())
              .font(.footnote)
            Text(model.job.jobType.label)
            if let resultText = model.job.resultText {
              Text(resultText)
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            if model.isLoading {
              IndeterminateProgressView()
                .padding(.top)
            }
          }
          .padding(.leading, 10)

          if isExpanded {
            Text("User ID")
              .font(.subheadline)
              .fontWeight(.medium)
              .padding(.top, 10)
              .padding(.leading, 10)
            Text(model.job.userId)
              .font(.footnote)
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .enableTextSelection(model.job.userId)
            Text("Job ID")
              .font(.subheadline)
              .fontWeight(.medium)
              .padding(.top, 10)
              .padding(.leading, 10)
            Text(model.job.jobId)
              .font(.footnote)
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .enableTextSelection(model.job.jobId)

            Group {
              Text("Partner ID")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, 10)
              Text(model.job.partnerId)
                .font(.footnote)
                .padding(.vertical, 5)

              Text("Environment")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, 10)
              Text(model.job.isProduction ? "Production" : "Sandbox")
                .font(.footnote)
                .padding(.vertical, 5)

              if let smileJobId = model.job.smileJobId {
                Text("Smile Job ID")
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .padding(.top, 10)
                Text(smileJobId)
                  .font(.footnote)
                  .padding(.vertical, 5)
              }
              if let resultCode = model.job.resultCode {
                Text("Result Code")
                  .font(.subheadline)
                  .fontWeight(.medium)
                  .padding(.top, 10)
                Text(resultCode)
                  .font(.footnote)
                  .padding(.vertical, 5)
              }
              if let code = model.job.code {
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
    .onAppear {
      Task {
        try await model.updateJobStatus()
      }
    }
    .onDisappear {
      model.cancelTask()
    }
  }
}

#if DEBUG
  #Preview {
    JobListItem(
      model: JobItemModel(job: .documentVerification)
    )
  }
#endif
