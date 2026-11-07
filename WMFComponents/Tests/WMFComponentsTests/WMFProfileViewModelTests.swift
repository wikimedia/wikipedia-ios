import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

enum ProfileTestAccount: CaseIterable, Sendable {
    case permanent
    case temporary
    case loggedOut

    var isLoggedIn: Bool { self == .permanent }
    var isTemporaryAccount: Bool { self == .temporary }

    /// The rows of each section, by title, when no developer setting is on.
    var expectedRows: [[String]] {
        switch self {
        case .permanent:
            return [["notifications"], ["userPage", "talkPage", "watchlist", "logOut"], ["donate"], ["settings"]]
        case .temporary:
            return [["notifications"], ["userPage", "talkPage", "join"], ["donate"], ["settings"]]
        case .loggedOut:
            return [["join"], ["donate"], ["settings"]]
        }
    }

    var expectedSubtexts: [String?] {
        switch self {
        case .permanent:
            return [nil, nil, nil, nil]
        case .temporary:
            return [nil, "joinSubtext", "donateSubtext", nil]
        case .loggedOut:
            return ["joinSubtext", "donateSubtext", nil]
        }
    }

    /// What tapping each row sends to the coordinator, in order.
    var expectedActions: [String: [ProfileAction]] {
        let shared: [String: [ProfileAction]] = [
            "donate": [.showDonate, .logDonateTap],
            "settings": [.showSettings]
        ]
        let specific: [String: [ProfileAction]]
        switch self {
        case .permanent:
            specific = [
                "notifications": [.showNotifications],
                "userPage": [.showUserPage],
                "talkPage": [.showUserTalkPage],
                "watchlist": [.showWatchlist],
                "logOut": [.logout]
            ]
        case .temporary:
            specific = [
                "notifications": [.showNotifications],
                "userPage": [.showUserPageTempAccount],
                "talkPage": [.showUserTalkPageTempAccount],
                "join": [.login]
            ]
        case .loggedOut:
            specific = ["join": [.login]]
        }
        return shared.merging(specific) { first, _ in first }
    }

    /// The rows that UI tests find by identifier. Every other row has none.
    @MainActor var expectedAccessibilityIdentifiers: [String: String] {
        let settings = ["settings": AccessibilityIdentifiers.Profile.settingsRow]
        let specific: [String: String]
        switch self {
        case .permanent:
            specific = [:]
        case .temporary:
            specific = [
                "userPage": AccessibilityIdentifiers.Profile.temporaryAccountUserPageRow,
                "join": AccessibilityIdentifiers.Profile.joinWikipediaRow
            ]
        case .loggedOut:
            specific = ["join": AccessibilityIdentifiers.Profile.joinWikipediaRow]
        }
        return settings.merging(specific) { first, _ in first }
    }
}

private final class RecordingProfileCoordinatorDelegate: ProfileCoordinatorDelegate {
    var actions: [ProfileAction] = []

    func handleProfileAction(_ action: ProfileAction) {
        actions.append(action)
    }
}

@MainActor
@Suite(.serialized)
final class WMFProfileViewModelTests {

    private let fixture = WMFDataTestFixture()
    private let developerSettingsTitle = "Developer settings"
    private let yearInReviewTitle = "YIR 2026 Test"

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }

    private var localizedStrings: WMFProfileViewModel.LocalizedStrings {
        WMFProfileViewModel.LocalizedStrings(
            pageTitle: "page",
            notificationsTitle: "notifications",
            userPageTitle: "userPage",
            talkPageTitle: "talkPage",
            watchlistTitle: "watchlist",
            logOutTitle: "logOut",
            donateTitle: "donate",
            settingsTitle: "settings",
            joinWikipediaTitle: "join",
            joinWikipediaSubtext: "joinSubtext",
            donateSubtext: "donateSubtext",
            yearInReviewTitle: "yearInReview",
            yearInReviewLoggedOutSubtext: "yearInReviewSubtext"
        )
    }

    private func makeViewModel(
        _ account: ProfileTestAccount,
        inboxCount: Int = 0,
        delegate: ProfileCoordinatorDelegate? = nil
    ) -> WMFProfileViewModel {
        WMFProfileViewModel(
            isLoggedIn: account.isLoggedIn,
            isTemporaryAccount: account.isTemporaryAccount,
            localizedStrings: localizedStrings,
            inboxCount: inboxCount,
            coordinatorDelegate: delegate
        )
    }

    private func rowTitles(_ viewModel: WMFProfileViewModel) -> [[String]] {
        viewModel.profileSections.map { section in section.listItems.map(\.text) }
    }

    private func allRows(_ viewModel: WMFProfileViewModel) -> [ProfileListItem] {
        viewModel.profileSections.flatMap(\.listItems)
    }

    private func row(_ title: String, in viewModel: WMFProfileViewModel) throws -> ProfileListItem {
        try #require(allRows(viewModel).first { $0.text == title })
    }

    private func tap(_ title: String, in viewModel: WMFProfileViewModel, delegate: RecordingProfileCoordinatorDelegate) throws -> [ProfileAction] {
        delegate.actions = []
        _ = try row(title, in: viewModel).action()
        return delegate.actions
    }

    // MARK: - Layout

    @Test(arguments: ProfileTestAccount.allCases)
    func sectionsMatchTheAccountState(account: ProfileTestAccount) async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(account)

            #expect(rowTitles(viewModel) == account.expectedRows)
            #expect(viewModel.profileSections.map(\.subtext) == account.expectedSubtexts)
        }
    }

    @Test(arguments: ProfileTestAccount.allCases)
    func everyRowHasAnImage(account: ProfileTestAccount) async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(account)

            #expect(allRows(viewModel).allSatisfy { $0.image != nil })
        }
    }

    @Test
    func onlyATemporaryAccountGetsTheTemporaryAccountIcon() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let temporaryAccountIcon = try #require(WMFIcon.temp)

            let temporaryRow = try row("userPage", in: makeViewModel(.temporary))
            let permanentRow = try row("userPage", in: makeViewModel(.permanent))

            #expect(temporaryRow.image === temporaryAccountIcon)
            #expect(permanentRow.image !== temporaryAccountIcon)
        }
    }

    @Test(arguments: ProfileTestAccount.allCases)
    func accessibilityIdentifiersMatchTheAccountState(account: ProfileTestAccount) async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(account)
            let identifiers = allRows(viewModel).reduce(into: [String: String]()) { result, row in
                result[row.text] = row.accessibilityIdentifier
            }

            #expect(identifiers == account.expectedAccessibilityIdentifiers)
        }
    }

    @Test(arguments: ProfileTestAccount.allCases)
    func isUserLoggedInIsTrueOnlyForAPermanentAccount(account: ProfileTestAccount) async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(makeViewModel(account).isUserLoggedIn() == (account == .permanent))
        }
    }

    // MARK: - Actions

    @Test(arguments: ProfileTestAccount.allCases)
    func eachRowSendsItsActionToTheCoordinator(account: ProfileTestAccount) async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let delegate = RecordingProfileCoordinatorDelegate()
            let viewModel = makeViewModel(account, delegate: delegate)
            var actions: [String: [ProfileAction]] = [:]

            for row in allRows(viewModel) {
                actions[row.text] = try tap(row.text, in: viewModel, delegate: delegate)
            }

            #expect(actions == account.expectedActions)
        }
    }

    // MARK: - Developer settings

    @Test(arguments: ProfileTestAccount.allCases)
    func developerModeAddsItsRowAfterSettings(account: ProfileTestAccount) async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode = true
            let delegate = RecordingProfileCoordinatorDelegate()
            let viewModel = makeViewModel(account, delegate: delegate)
            var expected = account.expectedRows
            expected[expected.count - 1] = ["settings", developerSettingsTitle]

            #expect(rowTitles(viewModel) == expected)
            let actions = try tap(developerSettingsTitle, in: viewModel, delegate: delegate)
            #expect(actions == [.showDevSettings])
        }
    }

    @Test(arguments: ProfileTestAccount.allCases)
    func forcedYearInReviewEntryPointAddsItsRowAfterSettings(account: ProfileTestAccount) async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceYiREntryPoint2026 = true
            let delegate = RecordingProfileCoordinatorDelegate()
            let viewModel = makeViewModel(account, delegate: delegate)
            var expected = account.expectedRows
            expected[expected.count - 1] = ["settings", yearInReviewTitle]

            #expect(rowTitles(viewModel) == expected)
            let actions = try tap(yearInReviewTitle, in: viewModel, delegate: delegate)
            #expect(actions == [.showYearInReview])
        }
    }

    @Test(arguments: ProfileTestAccount.allCases)
    func bothDeveloperRowsAppearInOrder(account: ProfileTestAccount) async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode = true
            WMFDeveloperSettingsDataController.shared.forceYiREntryPoint2026 = true
            let viewModel = makeViewModel(account)

            #expect(rowTitles(viewModel).last == ["settings", developerSettingsTitle, yearInReviewTitle])
        }
    }

    // MARK: - Notifications badge

    @Test(arguments: [ProfileTestAccount.permanent, .temporary], [(0, false), (1, true), (12, true)])
    func notificationsRowShowsABadgeOnlyWithUnreadItems(account: ProfileTestAccount, inbox: (count: Int, hasNotifications: Bool)) async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(account, inboxCount: inbox.count)
            let notificationsRow = try row("notifications", in: viewModel)

            #expect(viewModel.inboxCount == inbox.count)
            #expect(notificationsRow.hasNotifications == inbox.hasNotifications)
            #expect(notificationsRow.needsNotificationCount)
        }
    }

    @Test(arguments: ProfileTestAccount.allCases)
    func onlyTheNotificationsRowCarriesABadge(account: ProfileTestAccount) async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(account, inboxCount: 3)
            let otherRows = allRows(viewModel).filter { $0.text != "notifications" }

            #expect(otherRows.allSatisfy { $0.hasNotifications == nil && !$0.needsNotificationCount })
        }
    }

    // MARK: - Donate loading

    @Test(arguments: ProfileTestAccount.allCases)
    func onlyTheDonateRowIsMarkedAsDonate(account: ProfileTestAccount) async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(account)

            #expect(allRows(viewModel).filter(\.isDonate).map(\.text) == ["donate"])
        }
    }

    @Test(arguments: ProfileTestAccount.allCases)
    func loadingDonateConfigsRebuildsOnlyTheDonateRow(account: ProfileTestAccount) async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let delegate = RecordingProfileCoordinatorDelegate()
            let viewModel = makeViewModel(account, delegate: delegate)
            #expect(allRows(viewModel).allSatisfy { !$0.isLoadingDonateConfigs })

            viewModel.isLoadingDonateConfigs = true

            #expect(allRows(viewModel).filter(\.isLoadingDonateConfigs).map(\.text) == ["donate"])
            #expect(rowTitles(viewModel) == account.expectedRows)
            let actions = try tap("donate", in: viewModel, delegate: delegate)
            #expect(actions == [.showDonate, .logDonateTap])

            viewModel.isLoadingDonateConfigs = false

            #expect(allRows(viewModel).allSatisfy { !$0.isLoadingDonateConfigs })
        }
    }
}
