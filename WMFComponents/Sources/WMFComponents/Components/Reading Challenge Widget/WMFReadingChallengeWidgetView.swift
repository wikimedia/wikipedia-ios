import SwiftUI
import WidgetKit

public struct WMFReadingChallengeWidgetView: View {

    @ObservedObject var viewModel: WMFReadingChallengeWidgetViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.widgetFamily) var widgetFamily

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    // MARK: - Init

    public init(viewModel: WMFReadingChallengeWidgetViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    // MARK: - Small View

    var smallView: some View {
        switch viewModel.state {
        case .streakOngoingRead:
            AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.localizedStrings.title)
                        .font(Font(WMFFont.for(.boldTitle3)))
                        .foregroundColor(Color(uiColor: theme.text))
                    if let displaySet = viewModel.state.displaySets.first,
                       let uiImage = UIImage(named: displaySet.image, in: .module, with: nil) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                    }
                    Text(viewModel.localizedStrings.subtitle)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                }
                .padding()
            )
        default:
            AnyView(EmptyView())
        }
    }

    // MARK: - Medium View

    var mediumView: some View {
        switch viewModel.state {
        case .streakOngoingRead:
            AnyView(
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.localizedStrings.title)
                            .font(Font(WMFFont.for(.boldTitle3)))
                            .foregroundColor(Color(uiColor: theme.text))
                        if let displaySet = viewModel.state.displaySets.first,
                           let uiImage = UIImage(named: displaySet.image, in: .module, with: nil) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                        }
                        Text(viewModel.localizedStrings.subtitle)
                            .font(Font(WMFFont.for(.subheadline)))
                            .foregroundColor(Color(uiColor: theme.secondaryText))
                    }
                    Spacer()
                }
                .padding()
            )
        default:
            AnyView(EmptyView())
        }
    }
}
