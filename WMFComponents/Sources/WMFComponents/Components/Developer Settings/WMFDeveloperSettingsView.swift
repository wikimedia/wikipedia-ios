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
            .listRowBackground(rowBackground)

            Section {
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
                    .foregroundStyle(Color(theme.link))
                }
            } header: {
                sectionHeader("App install ID")
            } footer: {
                sectionFooter("Tap to copy. Use it to find this install's errors in Logstash.")
            }
            .listRowBackground(rowBackground)

            Section {
                captionedRow(caption: "Always show the entry point. When this is off, the other Year in Review settings have no effect.") {
                    Toggle("Show Year in Review 2026", isOn: $viewModel.forceYiREntryPoint2026)
                }
                captionedRow(caption: "Overrides the experience the personalized data selects. Switching it back to Off lets the user data dictate the experience.") {
                    Picker("Force Experience", selection: $viewModel.forceYiRUserDataState) {
                        Text("Off").tag(WMFYearInReviewDataController.YiRUserDataState?.none)
                        Text("Data Rich Experience").tag(WMFYearInReviewDataController.YiRUserDataState?.some(.dataRich))
                        Text("Data Low Experience").tag(WMFYearInReviewDataController.YiRUserDataState?.some(.lowData))
                    }
                    .tint(Color(theme.secondaryText))
                }
                .disabled(!viewModel.forceYiREntryPoint2026)
                captionedRow(caption: "Shows the announcement on every eligible app open, without the remote config, the settings toggle, the country gate, or the already seen state.") {
                    Toggle("Force Year in Review 2026 Announcement", isOn: $viewModel.forceYiR2026Announcement)
                }
                .disabled(!viewModel.forceYiREntryPoint2026)
            } header: {
                sectionHeader("Year in Review")
            }
            .listRowBackground(rowBackground)

            Section {
                captionedRow(caption: "Fakes a successful donation without a real charge. The native form skips the payment submission, and the web form goes straight to the thank you page.") {
                    Toggle(viewModel.localizedStrings.bypassDonation, isOn: $viewModel.bypassDonation)
                }
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
                    .tint(Color(theme.link))
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
                    .tint(Color(theme.secondaryText))
                }
                captionedRow(caption: "Resets \"maybe later\" / \"already donated\", the local donation history, the saved donation reminder, the experiment bucket, and the wrap-up card, so the banner can show again and the next Maybe Later re-rolls the A/B/C assignment.") {
                    Button {
                        viewModel.clearFundraisingCampaignPersistence()
                    } label: {
                        Text("Clear banner prompt state and donation history")
                            .foregroundStyle(Color(theme.link))
                    }
                }
            } header: {
                sectionHeader("Fundraising")
            }
            .listRowBackground(rowBackground)

            Section {
                captionedRow(caption: "Keeps the semantic search entry point hidden in production. Without this, no gate below is evaluated.") {
                    Toggle("Enable Semantic Search", isOn: $viewModel.enableSemanticSearch)
                }
                captionedRow(caption: "Overrides the persisted A/B bucket at read time; the target language gate still applies. Switching it back to Off restores the persisted bucket.") {
                    Picker("Force Experiment Group", selection: $viewModel.forceSemanticSearchExperimentAssignment) {
                        Text("Off").tag(WMFSemanticSearchDataController.ExperimentAssignment?.none)
                        Text("Control (A)").tag(WMFSemanticSearchDataController.ExperimentAssignment?.some(.control))
                        Text("Group B").tag(WMFSemanticSearchDataController.ExperimentAssignment?.some(.groupB))
                    }
                    .tint(Color(theme.secondaryText))
                }
                captionedRow(caption: "Removes the persisted bucket so the next eligible search re-rolls the A/B assignment.") {
                    Button {
                        viewModel.clearSemanticSearchExperimentAssignment()
                    } label: {
                        Text("Clear experiment assignment")
                            .foregroundStyle(Color(theme.link))
                    }
                }
                captionedRow(caption: "Forgets the hidden state and the first use, so the entry point shows again with Try it now.") {
                    Button {
                        viewModel.resetSemanticSearchEntryPoint()
                    } label: {
                        Text("Reset entry point")
                            .foregroundStyle(Color(theme.link))
                    }
                }
            } header: {
                sectionHeader("Semantic Search")
            }
            .listRowBackground(rowBackground)

            if let widgetDiagnostics = viewModel.widgetDiagnostics {
                Section {
                    ForEach(Array(widgetDiagnostics.cacheSummaryLines.enumerated()), id: \.offset) { _, line in
                        diagnosticLine(line)
                    }
                    Button {
                        viewModel.clearWidgetCacheAndReloadWidgets()
                    } label: {
                        Text("Clear cache and reload widgets")
                            .foregroundStyle(Color(theme.link))
                    }
                } header: {
                    sectionHeader("Widgets")
                } footer: {
                    sectionFooter("Cached feed content shared by the Featured Article, Top Read and Picture of the Day widgets.")
                }
                .listRowBackground(rowBackground)

                Section {
                    if widgetDiagnostics.lastFetchLines.isEmpty {
                        diagnosticLine("No widget fetch recorded yet.")
                    } else {
                        ForEach(Array(widgetDiagnostics.lastFetchLines.enumerated()), id: \.offset) { _, line in
                            diagnosticLine(line)
                        }
                    }
                } header: {
                    sectionHeader("Last widget fetch")
                } footer: {
                    sectionFooter("A section that failed to decode is listed with the JSON path that broke. Dropped elements are articles or events skipped inside a section.")
                }
                .listRowBackground(rowBackground)
            }

            ForEach(viewModel.formViewModel.sections) { section in
                if let selectSection = section as? WMFFormSectionSelectViewModel {
                    WMFFormSectionSelectView(viewModel: selectSection)
                        .listRowBackground(rowBackground)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .listBackgroundColor(Color(theme.baseBackground))
        .foregroundStyle(Color(theme.text))
        .toggleStyle(SwitchToggleStyle(tint: Color(theme.accent)))
    }

    private var rowBackground: some View {
        Color(theme.paperBackground).edgesIgnoringSafeArea([.all])
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Font(WMFFont.for(.boldFootnote)))
            .foregroundStyle(Color(theme.secondaryText))
    }

    private func sectionFooter(_ text: String) -> some View {
        Text(text)
            .font(Font(WMFFont.for(.caption1)))
            .foregroundStyle(Color(theme.secondaryText))
    }

    private func diagnosticLine(_ line: String) -> some View {
        Text(line)
            .font(Font(WMFFont.for(.caption1)))
            .foregroundStyle(Color(theme.text))
            .textSelection(.enabled)
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
