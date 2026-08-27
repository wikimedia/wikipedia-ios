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

            Section(header: Text("App install ID"), footer: Text("Tap to copy. Use it to find this install's errors in Logstash.")) {
                Button {
                    viewModel.copyAppInstallID()
                } label: {
                    HStack {
                        Text(viewModel.appInstallID ?? "Unavailable")
                            .font(Font(WMFFont.for(.callout)))
                        Spacer()
                        if let copyIcon = WMFSFSymbolIcon.for(symbol: .docOnDoc) {
                            Image(uiImage: copyIcon)
                        }
                    }
                }
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
