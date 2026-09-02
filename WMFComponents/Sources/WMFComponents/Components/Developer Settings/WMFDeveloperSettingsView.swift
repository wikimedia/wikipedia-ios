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

            Section {
                Toggle("Bypass Reminder Daily Limit", isOn: $viewModel.bypassDonationReminderDailyLimit)
                fundraisingRow(caption: "Changes the date the donation reminder end gate treats as today; reading progress, the daily limit, and networking keep using the real device date.") {
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
                fundraisingRow(caption: "Ignores country and language settings. Only works if there is an active campaign.") {
                    Toggle("Force Fundraising Campaign Banner", isOn: $viewModel.forceFundraisingCampaignBanner)
                }
                fundraisingRow(caption: "Fetches the donate and campaign configs from test.wikipedia.org instead of donate.wikimedia.org; toggling clears the cached configs and refetches immediately.") {
                    Toggle("Use Test Wiki Donate Configs", isOn: $viewModel.useTestWikiDonateConfigs)
                }
                fundraisingRow(caption: "Skips the getPaymentMethods API call and enables Apple Pay with the standard card networks; use it when the payments API rate limits the device.") {
                    Toggle("Use Hardcoded Payment Methods", isOn: $viewModel.useHardcodedPaymentMethods)
                }
                fundraisingRow(caption: "Overrides the persisted A/B/C bucket at read time; switching it back to Off restores the persisted bucket.") {
                    Picker("Force Reminder Experiment Group", selection: $viewModel.forceDonationReminderExperimentAssignment) {
                        Text("Off").tag(WMFDonationReminderDataController.ExperimentAssignment?.none)
                        Text("Control (A)").tag(WMFDonationReminderDataController.ExperimentAssignment?.some(.control))
                        Text("Group B").tag(WMFDonationReminderDataController.ExperimentAssignment?.some(.groupB))
                        Text("Group C").tag(WMFDonationReminderDataController.ExperimentAssignment?.some(.groupC))
                    }
                }
                fundraisingRow(caption: "Resets \"maybe later\" / \"already donated\", the local donation history, the saved donation reminder, the experiment bucket, and the wrap-up card, so the banner can show again and the next Maybe Later re-rolls the A/B/C assignment.") {
                    Button {
                        viewModel.clearFundraisingCampaignPersistence()
                    } label: {
                        Text("Clear banner prompt state and donation history")
                    }
                }
            } header: {
                Text("Fundraising")
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

    private func fundraisingRow(caption: String, @ViewBuilder control: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            control()
            Text(caption)
                .font(Font(WMFFont.for(.caption1)))
                .foregroundStyle(Color(theme.secondaryText))
        }
    }
}
