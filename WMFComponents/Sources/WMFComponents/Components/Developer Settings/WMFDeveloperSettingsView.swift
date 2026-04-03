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
            ForEach(viewModel.formViewModel.sections) { section in
                if let selectSection = section as? WMFFormSectionSelectViewModel {
                    WMFFormSectionSelectView(viewModel: selectSection)
                        .listRowBackground(Color(theme.paperBackground).edgesIgnoringSafeArea([.all]))
                    // Inject stepper row directly after the forced state section
                    if selectSection.header == "Force Reading Challenge State" {
                        Section {
                            HStack {
                                Text("Streak days: \(viewModel.streakCount)")
                                    .foregroundColor(Color(theme.text))
                                    .font(Font(WMFFont.for(.callout)))
                                Spacer()
                                Stepper("", value: Binding(
                                    get: { viewModel.streakCount },
                                    set: { viewModel.setStreakCount($0) }
                                ), in: 1...25)
                                .labelsHidden()
                            }
                            .listRowBackground(Color(theme.paperBackground))
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .listBackgroundColor(Color(theme.baseBackground))
    }
}
