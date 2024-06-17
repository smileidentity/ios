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
                Image(.document)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .clipped()
                VStack(alignment: .leading) {
                    Text("13/06/2024 16:46")
                        .font(.footnote)
                    Text("Document Verification")
                    Text("Document Verified")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if isExpanded {
                        Text("User ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 5)
                        Text("user-8a48173d-f44f-4db4-a833-8dd051c8940b")
                            .font(.footnote)
                        Text("Job ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 5)
                        Text("job-07239563-962d-48c6-8f8b-39fe590d5030")
                            .font(.footnote)
                        Text("Smile Job ID")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 5)
                        Text("job-07239563-962d-48c6-8f8b-39fe590d5030")
                            .font(.footnote)
                        Text("Result Code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 5)
                        Text("0801")
                            .font(.footnote)
                        Text("Code")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.top, 5)
                        Text("2302")
                            .font(.footnote)
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
