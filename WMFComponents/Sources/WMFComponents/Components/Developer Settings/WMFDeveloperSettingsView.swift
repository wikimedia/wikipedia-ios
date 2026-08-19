import Foundation
import SwiftUI
import Combine
import WMFData

struct WMFDeveloperSettingsView: View {

    @ObservedObject var viewModel: WMFDeveloperSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    var body: some View {
        List {
            
            Section {
                Toggle("Enable Developer Mode", isOn: $viewModel.enableDeveloperMode)
            }

            Section(header: Text("Games")) {
                Toggle("Show Games Version 2", isOn: $viewModel.showGamesV2)
                Button {
                    viewModel.clearGamesPersistence()
                } label: {
                    Text("Clear games persistence")
                }
            }

            Section(header: Text("Visual Editor")) {
                Toggle("Enable Visual Editing journey", isOn: $viewModel.enableVisualEditingJourney)
                Button {
                    viewModel.clearDefaultEditMode()
                } label: {
                    Text("Clear default edit mode")
                }
            }

            Section {
                Toggle("Force Fundraising Campaign Banner", isOn: $viewModel.forceFundraisingCampaignBanner)
            } header: {
                Text("Fundraising")
            } footer: {
                Text("Force ignores country and language settings. Only works if there is an active campaign.")
            }

            ForEach(viewModel.formViewModel.sections) { section in
                if let selectSection = section as? WMFFormSectionSelectViewModel {
                    WMFFormSectionSelectView(viewModel: selectSection)
                        .listRowBackground(Color(theme.paperBackground).edgesIgnoringSafeArea([.all]))
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .listBackgroundColor(Color(theme.baseBackground))
    }
}
