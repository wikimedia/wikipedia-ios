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
                .onChange(of: viewModel.isTimeSpentReadingOn) { newValue in
                    guard newValue == true else { return }
                    guard viewModel.isLoggedIn else {
                        viewModel.isTimeSpentReadingOn = false
                        viewModel.presentLoggedInToastAction?()
                        return
                    }
                }

                Toggle(
                    viewModel.localizedStrings.readingInsights,
                    isOn: $viewModel.isReadingInsightsOn
                )
                .onChange(of: viewModel.isReadingInsightsOn) { newValue in
                    guard newValue == true else { return }
                    guard viewModel.isLoggedIn else {
                        viewModel.isReadingInsightsOn = false
                        viewModel.presentLoggedInToastAction?()
                        return
                    }
                }

                Toggle(
                    viewModel.localizedStrings.editingInsights,
                    isOn: $viewModel.isEditingInsightsOn
                )
                .onChange(of: viewModel.isEditingInsightsOn) { newValue in
                    guard newValue == true else { return }
                    guard viewModel.isLoggedIn else {
                        viewModel.isEditingInsightsOn = false
                        viewModel.presentLoggedInToastAction?()
                        return
                    }
                }

                Toggle(
                    viewModel.localizedStrings.allTimeImpact,
                    isOn: $viewModel.isAllTimeImpactOn
                )
                .onChange(of: viewModel.isAllTimeImpactOn) { newValue in
                    guard newValue == true else { return }
                    guard viewModel.isLoggedIn else {
                        viewModel.isAllTimeImpactOn = false
                        viewModel.presentLoggedInToastAction?()
                        return
                    }
                }

                Toggle(
                    viewModel.localizedStrings.lastInAppDonation,
                    isOn: $viewModel.isLastInAppDonationOn
                )
                .onChange(of: viewModel.isLastInAppDonationOn) { newValue in
                    guard newValue == true else { return }
                    guard viewModel.isLoggedIn else {
                        viewModel.isLastInAppDonationOn = false
                        viewModel.presentLoggedInToastAction?()
                        return
                    }
                }

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
