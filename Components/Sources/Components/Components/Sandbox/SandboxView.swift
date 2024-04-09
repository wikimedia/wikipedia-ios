import SwiftUI

struct SandboxView: View {
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    let viewModel: SandboxViewModel
    var body: some View {
        List {
            SandboxViewCell(sandboxTitle: "San Francisco", sandboxTopic: "Geography")
            SandboxViewCell(sandboxTitle: "California", sandboxTopic: "Geography")
            SandboxViewCell(sandboxTitle: "USA", sandboxTopic: "Geography")
            SandboxViewCell(sandboxTitle: "Earth", sandboxTopic: "Astronomy")
            SandboxViewCell(sandboxTitle: "Milky Way", sandboxTopic: "Astronomy")
        }
    }
}


struct SandboxViewCell: View {
    @ObservedObject var appEnvironment = WKAppEnvironment.current
    var sandboxTitle: String
    var sandboxTopic: String

    var body: some View {
        Text(sandboxTitle)
            .font(Font(WKFont.for(.boldCallout)))
            .foregroundColor(Color(appEnvironment.theme.text))

        Text(sandboxTopic)
            .font(Font(WKFont.for(.callout)))
            .foregroundColor(Color(appEnvironment.theme.secondaryText))

    }
}
