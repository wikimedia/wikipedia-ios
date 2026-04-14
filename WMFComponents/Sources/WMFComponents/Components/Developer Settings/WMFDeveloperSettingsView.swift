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
                }
            }
            
            Section(header: Text("Reading Challenge Widget")) {
                Toggle("Override Current Date", isOn: $viewModel.readingChallengeOverrideCurrentDate)

                if viewModel.readingChallengeOverrideCurrentDate {
                    DatePicker(
                        "",
                        selection: $viewModel.readingChallengeCurrentDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
                
                Button {
                    viewModel.clearAllReadingChallengePersistence()
                } label: {
                    Text("Clear all widget persistence")
                }

            }
        }
        .listStyle(InsetGroupedListStyle())
        .listBackgroundColor(Color(theme.baseBackground))
    }
}
