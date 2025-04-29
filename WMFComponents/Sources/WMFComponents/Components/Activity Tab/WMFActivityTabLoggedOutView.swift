import SwiftUI

struct WMFActivityTabLoggedOutView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var openHistory: () -> Void
    var loginAction: () -> Void
    
    let viewModel: WMFActivityViewModel
    
    public init(viewModel: WMFActivityViewModel, loginAction: @escaping () -> Void, openHistory: @escaping () -> Void) {
        self.viewModel = viewModel
        self.loginAction = loginAction
        self.openHistory = openHistory
        self.loginAction = loginAction
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.localizedStrings.loggedOutTitle)
                .font(Font(WMFFont.for(.headline)))
                .foregroundColor(Color(theme.text))
                .padding(.bottom, 8)
            Text(viewModel.localizedStrings.loggedOutSubtitle)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(Color(theme.secondaryText))

            WMFLargeButton(configuration: .primary, title: viewModel.localizedStrings.logIn, action: loginAction)
            WMFLargeButton(configuration: .secondary, title: viewModel.localizedStrings.viewHistory, action: openHistory)

            Spacer()
        }
        .padding(20)

    }
}
