import Foundation
import SwiftUI
import Combine
import WMFData

private extension ReadingChallengeState {
    static func allCasesForPicker(streakCount: Int) -> [(label: String, state: ReadingChallengeState?)] {
        [
            ("None (no override)", nil),
            ("Challenge Removed", .challengeRemoved),
            ("Not Live Yet", .notLiveYet),
            ("Not Enrolled", .notEnrolled),
            ("Enrolled Not Started", .enrolledNotStarted),
            ("Streak Ongoing Read", .streakOngoingRead(streak: streakCount)),
            ("Streak Ongoing Not Yet Read", .streakOngoingNotYetRead(streak: streakCount)),
            ("Challenge Completed", .challengeCompleted),
            ("Concluded Incomplete", .challengeConcludedIncomplete(streak: streakCount)),
            ("Concluded No Streak", .challengeConcludedNoStreak)
        ]
    }

    var isStreakState: Bool {
        switch self {
        case .streakOngoingRead, .streakOngoingNotYetRead, .challengeConcludedIncomplete: return true
        default: return false
        }
    }
}

struct WMFDeveloperSettingsView: View {

    @ObservedObject var viewModel: WMFDeveloperSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    var body: some View {
        List {
            
            Section {
                Toggle("Enable Developer Mode", isOn: $viewModel.enableDeveloperMode)
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

                Picker("Override State", selection: $viewModel.readingChallengeState) {
                    ForEach(ReadingChallengeState.allCasesForPicker(streakCount: viewModel.readingChallengeStreakCount), id: \.label) { option in
                        Text(option.label).tag(option.state)
                    }
                }

                if viewModel.readingChallengeState?.isStreakState == true {
                    Stepper("Streak Count: \(viewModel.readingChallengeStreakCount)", value: $viewModel.readingChallengeStreakCount, in: 1...24)
                }

                Button {
                    viewModel.clearAllReadingChallengePersistence()
                } label: {
                    Text("Clear all widget persistence")
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
