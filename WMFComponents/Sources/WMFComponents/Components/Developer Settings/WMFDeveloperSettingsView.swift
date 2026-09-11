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

            Section {
                Toggle("Bypass Reminder Daily Limit", isOn: $viewModel.bypassDonationReminderDailyLimit)
                captionedRow(caption: "Changes the date the donation reminder end gate treats as today; reading progress, the daily limit, and networking keep using the real device date.") {
                    Toggle("Override Current Date", isOn: $viewModel.overrideFundraisingCurrentDate)
                }
                if viewModel.overrideFundraisingCurrentDate {
                    DatePicker(
                        "Overridden current date",
                        selection: $viewModel.fundraisingCurrentDate,
                        in: viewModel.fundraisingOverrideDateRange,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
                captionedRow(caption: "Ignores country and language settings. Only works if there is an active campaign.") {
                    Toggle("Force Fundraising Campaign Banner", isOn: $viewModel.forceFundraisingCampaignBanner)
                }
                captionedRow(caption: "Fetches the donate and campaign configs from test.wikipedia.org instead of donate.wikimedia.org; toggling clears the cached configs and refetches immediately.") {
                    Toggle("Use Test Wiki Donate Configs", isOn: $viewModel.useTestWikiDonateConfigs)
                }
                captionedRow(caption: "Skips the getPaymentMethods API call and enables Apple Pay with the standard card networks; use it when the payments API rate limits the device.") {
                    Toggle("Use Hardcoded Payment Methods", isOn: $viewModel.useHardcodedPaymentMethods)
                }
                captionedRow(caption: "Overrides the persisted A/B/C bucket at read time; switching it back to Off restores the persisted bucket.") {
                    Picker("Force Reminder Experiment Group", selection: $viewModel.forceDonationReminderExperimentAssignment) {
                        Text("Off").tag(WMFDonationReminderDataController.ExperimentAssignment?.none)
                        Text("Control (A)").tag(WMFDonationReminderDataController.ExperimentAssignment?.some(.control))
                        Text("Group B").tag(WMFDonationReminderDataController.ExperimentAssignment?.some(.groupB))
                        Text("Group C").tag(WMFDonationReminderDataController.ExperimentAssignment?.some(.groupC))
                    }
                }
                captionedRow(caption: "Resets \"maybe later\" / \"already donated\", the local donation history, the saved donation reminder, the experiment bucket, and the wrap-up card, so the banner can show again and the next Maybe Later re-rolls the A/B/C assignment.") {
                    Button {
                        viewModel.clearFundraisingCampaignPersistence()
                    } label: {
                        Text("Clear banner prompt state and donation history")
                    }
                }
            } header: {
                Text("Fundraising")
            }

            Section {
                captionedRow(caption: "Keeps the semantic search entry point hidden in production. Without this, no gate below is evaluated.") {
                    Toggle("Enable Semantic Search", isOn: $viewModel.enableSemanticSearch)
                }
                captionedRow(caption: "Overrides the persisted A/B bucket at read time and bypasses the target language gate; switching it back to Off restores the persisted bucket.") {
                    Picker("Force Experiment Group", selection: $viewModel.forceSemanticSearchExperimentAssignment) {
                        Text("Off").tag(WMFSemanticSearchDataController.ExperimentAssignment?.none)
                        Text("Control (A)").tag(WMFSemanticSearchDataController.ExperimentAssignment?.some(.control))
                        Text("Group B").tag(WMFSemanticSearchDataController.ExperimentAssignment?.some(.groupB))
                    }
                }
                captionedRow(caption: "Removes the persisted bucket so the next eligible search re-rolls the A/B assignment.") {
                    Button {
                        viewModel.clearSemanticSearchExperimentAssignment()
                    } label: {
                        Text("Clear experiment assignment")
                    }
                }
            } header: {
                Text("Semantic Search")
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

    private func captionedRow(caption: String, @ViewBuilder control: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            control()
            Text(caption)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(theme.secondaryText))
        }
    }
}
