import SwiftUI

public struct WMFReadingChallengeWidgetView: View {

    @ObservedObject var viewModel: WMFReadingChallengeWidgetViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    // MARK: - Init

    public init(viewModel: WMFReadingChallengeWidgetViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.localizedStrings.title)
                .font(Font(WMFFont.for(.boldTitle3)))
                .foregroundColor(Color(uiColor: theme.text))
            Text(viewModel.localizedStrings.subtitle)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(uiColor: theme.secondaryText))
        }
        .padding()
    }
}
