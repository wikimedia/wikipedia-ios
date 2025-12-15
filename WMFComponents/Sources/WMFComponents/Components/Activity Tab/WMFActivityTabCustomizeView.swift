import SwiftUI
import Foundation
import WMFData

public struct WMFActivityTabCustomizeView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabCustomizeViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: WMFActivityTabCustomizeViewModel) {
        self.viewModel = viewModel
    }

    var theme: WMFTheme {
        appEnvironment.theme
    }

    public var body: some View {
        Form {
            Section {
                Toggle(
                    viewModel.localizedStrings.timeSpentReading,
                    isOn: $viewModel.isTimeSpentReadingOn
                )

                Toggle(
                    viewModel.localizedStrings.readingInsights,
                    isOn: $viewModel.isReadingInsightsOn
                )

                Toggle(
                    viewModel.localizedStrings.editingInsights,
                    isOn: $viewModel.isEditingInsightsOn
                )

                Toggle(
                    viewModel.localizedStrings.allTimeImpact,
                    isOn: $viewModel.isAllTimeImpactOn
                )

                Toggle(
                    viewModel.localizedStrings.lastInAppDonation,
                    isOn: $viewModel.isLastInAppDonationOn
                )

                Toggle(
                    viewModel.localizedStrings.timeline,
                    isOn: $viewModel.isTimelineOfBehaviorOn
                )
            } footer: {
                Text(viewModel.localizedStrings.footer)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
        }
        .background(Color(uiColor: theme.midBackground))
    }
}
