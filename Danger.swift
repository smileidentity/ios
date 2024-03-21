// swiftlint:disable all
import Danger

private extension Danger.File {
    var isInTests: Bool { hasPrefix("Example/Tests/") }

    var isSourceFile: Bool {
        hasSuffix(".swift") || hasSuffix(".h") || hasSuffix(".m")
    }
}

let danger = Danger()

let hasSourceChanges = (danger.git.modifiedFiles + danger.git.createdFiles).contains { $0.isSourceFile }
// SwiftLint
SwiftLint.lint(inline: true, configFile: "Sources/.swiftlint.yml")

// Encourage smaller PRs
let bigPRThreshold = 70
if danger.git.modifiedFiles.count > bigPRThreshold {
    warn("Pull Request size seems relatively large. If this Pull Request contains multiple changes,splitting each into separate PR will helps faster, easier review.")
}

// Make it more obvious that a PR is a work in progress and shouldn't be merged yet
if danger.github?.pullRequest.title.contains("WIP") == true {
    warn("PR is marked as Work in Progress")
}

// Warn when files has been updated but not tests.
if hasSourceChanges, !danger.git.modifiedFiles.contains(where: \.isInTests) {
    warn("The source files were changed, but the tests remain unmodified. Consider updating or adding to the tests to match the source changes.")
}
