import SwiftUI
import WMFData
import WMFNativeLocalizations

public struct WMFDiscoverSettingsView: View {
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    @ObservedObject private var viewModel: WMFDiscoverSettingsViewModel

    public init(viewModel: WMFDiscoverSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(uiColor: theme.midBackground)
                .ignoresSafeArea()

            List {
                Section(footer: footer(viewModel.footerText)) {
                    SettingsRow(item: toggleItem)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier(AccessibilityIdentifiers.Discover.settingsToggle)
                        .listRowBackground(Color(uiColor: theme.chromeBackground))
                        .listRowSeparator(.hidden)
                }

                if viewModel.settings.isEnabled {
                    Section(header: header(WMFDiscoverSettingsViewModel.yourListHeader)) {
                        articleCountRow
                        cadenceRow
                        sourceRow
                        if viewModel.showsInterestsRow {
                            interestsRow
                        }
                    }
                    .listRowBackground(Color(uiColor: theme.chromeBackground))
                    .listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .animation(.default, value: viewModel.settings.isEnabled)
            .animation(.default, value: viewModel.showsInterestsRow)
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.Discover.settingsView)
        .environment(\.colorScheme, theme.preferredColorScheme)
        .alert(WMFDiscoverSettingsViewModel.turnOffAlertTitle, isPresented: $viewModel.isShowingTurnOffAlert) {
            Button(WMFDiscoverSettingsViewModel.turnOffAlertConfirmTitle, role: .destructive) {
                viewModel.confirmTurnOff()
            }
            Button(CommonStrings.cancelActionTitle, role: .cancel) {
                viewModel.cancelTurnOff()
            }
        } message: {
            Text(viewModel.turnOffAlertMessage)
        }
    }

    // MARK: - Section texts

    private func header(_ text: String) -> some View {
        Text(text)
            .font(Font(WMFFont.for(.footnote)))
            .foregroundStyle(Color(uiColor: theme.secondaryText))
    }

    private func footer(_ text: String) -> some View {
        Text(text)
            .font(Font(WMFFont.for(.footnote)))
            .foregroundStyle(Color(uiColor: theme.secondaryText))
    }

    // MARK: - Rows

    private var toggleItem: SettingsItem {
        SettingsItem(image: nil, color: nil, title: WMFDiscoverSettingsViewModel.discoverReadingListTitle, subtitle: nil, accessory: .toggle(viewModel.isEnabledBinding), action: nil)
    }

    private var articleCountRow: some View {
        HStack(spacing: WMFSpacing.medium) {
            SettingsRow(item: SettingsItem(image: WMFSFSymbolIcon.for(symbol: .listBulletRectanglePortrait), color: WMFColor.blue600, title: WMFDiscoverSettingsViewModel.articleCountTitle, subtitle: nil, accessory: .none, action: nil))
            Text(viewModel.articleCountText)
                .font(Font(WMFFont.for(.body)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
            Stepper(WMFDiscoverSettingsViewModel.articleCountTitle, value: viewModel.articleCountBinding, in: WMFDiscoverSettings.articleCountRange)
                .labelsHidden()
                .accessibilityIdentifier(AccessibilityIdentifiers.Discover.settingsArticleCountStepper)
        }
    }

    private var cadenceRow: some View {
        HStack(spacing: WMFSpacing.medium) {
            SettingsRow(item: SettingsItem(image: WMFSFSymbolIcon.for(symbol: .arrowClockwise), color: WMFColor.green600, title: WMFDiscoverSettingsViewModel.cadenceTitle, subtitle: nil, accessory: .none, action: nil))
            Menu {
                Picker(WMFDiscoverSettingsViewModel.cadenceTitle, selection: viewModel.cadenceBinding) {
                    ForEach(WMFDiscoverCadence.allCases, id: \.self) { cadence in
                        Text(WMFDiscoverSettingsViewModel.cadenceValue(for: cadence))
                            .tag(cadence)
                    }
                }
            } label: {
                HStack(spacing: WMFSpacing.xSmall) {
                    Text(viewModel.cadenceValue)
                        .font(Font(WMFFont.for(.body)))
                    if let image = WMFSFSymbolIcon.for(symbol: .chevronUpChevronDown, font: WMFFont.caption1) {
                        Image(uiImage: image)
                    }
                }
                .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Discover.settingsCadenceMenu)
        }
    }

    private var sourceRow: some View {
        Button {
            viewModel.tapSource()
        } label: {
            SettingsRow(
                item: SettingsItem(
                    image: WMFSFSymbolIcon.for(symbol: .wrenchAdjustable),
                    color: WMFColor.orange600,
                    title: WMFDiscoverSettingsViewModel.sourceTitle,
                    subtitle: viewModel.sourceSubtitle,
                    accessory: .chevron(label: nil),
                    action: nil
                )
            )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Discover.settingsSourceRow)
    }

    private var interestsRow: some View {
        Button {
            viewModel.tapInterests()
        } label: {
            SettingsRow(item: SettingsItem(image: WMFSFSymbolIcon.for(symbol: .squareGrid2x2), color: WMFColor.purple600, title: WMFDiscoverSettingsViewModel.interestsTitle, subtitle: nil, accessory: .chevron(label: viewModel.interestCountText), action: nil))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifiers.Discover.settingsInterestsRow)
    }
}
