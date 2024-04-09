import SwiftUI

struct SandboxView: View {
    var body: some View {
        List {
            SandboxViewCell(sandboxTitle: "San Francisco", sandboxTopic: "Geography")
            SandboxViewCell(sandboxTitle: "California", sandboxTopic: "Geography")
            SandboxViewCell(sandboxTitle: "USA", sandboxTopic: "Geography")
            SandboxViewCell(sandboxTitle: "Earth", sandboxTopic: "Astronomy")
            SandboxViewCell(sandboxTitle: "Milky Way", sandboxTopic: "Astronomy")
        }
        .listStyle(.inset)
    }
}


struct SandboxViewCell: View {
    var sandboxTitle: String
    var sandboxTopic: String

    var body: some View {
        Text(sandboxTitle)

        Text(sandboxTopic)

    }
}
