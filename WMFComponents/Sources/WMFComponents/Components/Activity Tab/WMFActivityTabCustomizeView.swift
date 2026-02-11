import SwiftUI
import Foundation
import WMFData

public struct WMFActivityTabCustomizeView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFActivityTabCustomizeViewModel

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
                .listRowBackground(Color(theme.paperBackground).edgesIgnoringSafeArea([.all]))
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
                .listRowBackground(Color(theme.paperBackground).edgesIgnoringSafeArea([.all]))
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
                .listRowBackground(Color(theme.paperBackground).edgesIgnoringSafeArea([.all]))
                .onChange(of: viewModel.isEditingInsightsOn) { newValue in
                    guard newValue == true else { return }
                    guard viewModel.isLoggedIn else {
                        viewModel.isEditingInsightsOn = false
                        viewModel.presentLoggedInToastAction?()
                        return
                    }
                }

                Toggle(
                    viewModel.localizedStrings.timeline,
                    isOn: $viewModel.isTimelineOfBehaviorOn
                )
                .listRowBackground(Color(theme.paperBackground).edgesIgnoringSafeArea([.all]))
                .onChange(of: viewModel.isTimelineOfBehaviorOn) { newValue in
                    guard newValue == true else { return }
                    guard viewModel.isLoggedIn else {
                        viewModel.isTimelineOfBehaviorOn = false
                        viewModel.presentLoggedInToastAction?()
                        return
                    }
                }
            } footer: {
                Text(viewModel.localizedStrings.footer)
                    .font(Font(WMFFont.for(.caption1)))
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
                    .padding(.top, 12)
            }
        }
        .listRowBackground(Color(theme.paperBackground).edgesIgnoringSafeArea([.all]))
        .listStyle(GroupedListStyle())
        .listBackgroundColor(Color(theme.baseBackground))
        .onAppear(perform: {
            if #unavailable(iOS 16) {
                UITableView.appearance().backgroundColor = UIColor.clear
            }
        })
        .onDisappear(perform: {
            if #unavailable(iOS 16) {
                UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
            }
        })
    }
}
