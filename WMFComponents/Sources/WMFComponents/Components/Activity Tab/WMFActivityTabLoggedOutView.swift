import SwiftUI

struct WMFActivityTabLoggedOutView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var action: () -> Void = { }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Log in to see more reading and editing activity.")
                .font(Font(WMFFont.for(.headline)))
                .foregroundColor(Color(theme.text))
                .padding(.bottom, 8)
            Text("Track what you’ve read and view your contributions over time in a new way.")
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(theme.secondaryText))

            WMFLargeButton(configuration: .primary, title: "Log in", action: action)
            WMFLargeButton(configuration: .secondary, title: "View reading history", action: action)

            Spacer()
        }
        .padding(20)

    }
}
