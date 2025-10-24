import SwiftUI

// MARK: - Validation Error View

/// View displayed when validation fails (debug mode)
struct ValidationErrorView: View {
    let validationState: ValidationState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text("Validation Failed")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Please fix the following issues")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                
                // Issues
                ForEach(Array(validationState.issues.enumerated()), id: \.offset) { index, issue in
                    ValidationIssueRow(issue: issue, index: index + 1)
                }
            }
            .padding()
        }
    }
}

struct ValidationIssueRow: View {
    let issue: FlowValidationIssue
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index).")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(issue.severity.symbol)
                
                Text(issue.message)
                    .font(.body)
            }
            
            if let fix = issue.suggestedFix {
                HStack(alignment: .top) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Fix: \(fix)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 40)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
