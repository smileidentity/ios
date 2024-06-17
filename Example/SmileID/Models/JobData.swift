import Foundation
import SmileID

struct JobData: Identifiable {
    var id = UUID()
    let title: String
    let jobType: JobType
}
