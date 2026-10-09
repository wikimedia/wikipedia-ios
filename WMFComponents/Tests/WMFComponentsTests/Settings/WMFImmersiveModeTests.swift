import SwiftUI
import Testing
import WMFDataMocks
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData

/// Exercises the settings binding and the controller policy that together hide the status bar.
@Suite(.serialized)
@MainActor
final class WMFImmersiveModeTests {

	private let fixture = WMFDataTestFixture()

	@Test
	func toggleIsOffByDefaultAndAppearsAfterReadingPreferences() async throws {
		try await withConfiguredEnvironment {
			let viewModel = await makeViewModel()
			let binding = try immersiveModeBinding(in: viewModel)
			let items = viewModel.sections.flatMap(\.items)
			let readingPreferencesIndex = try #require(items.firstIndex { $0.title == viewModel.localizedStrings.readingpreferences })
			let immersiveModeIndex = try #require(items.firstIndex { $0.title == viewModel.localizedStrings.immersiveModeTitle })

			#expect(viewModel.isImmersiveModeEnabled == false)
			#expect(binding.wrappedValue == false)
			#expect(WMFAppEnvironment().isImmersiveModeEnabled == false)
			#expect(immersiveModeIndex == readingPreferencesIndex + 1)
			#expect(items[immersiveModeIndex].subtitle == viewModel.localizedStrings.immersiveModeSubtitle)
		}
	}

	/// Toggling the actual settings row must persist across newly constructed settings screens.
	@Test
	func togglingPersistsAndUpdatesTheSharedEnvironment() async throws {
		try await withConfiguredEnvironment {
			let viewModel = await makeViewModel()
			let binding = try immersiveModeBinding(in: viewModel)

			binding.wrappedValue = true

			#expect(viewModel.isImmersiveModeEnabled)
			#expect(binding.wrappedValue)
			#expect(WMFSettingsDataController.shared.immersiveModeEnabled())
			#expect(WMFAppEnvironment.current.isImmersiveModeEnabled)
			let reopenedViewModel = await makeViewModel()
			#expect(reopenedViewModel.isImmersiveModeEnabled)
			#expect(try immersiveModeBinding(in: reopenedViewModel).wrappedValue)

			binding.wrappedValue = false

			#expect(viewModel.isImmersiveModeEnabled == false)
			#expect(binding.wrappedValue == false)
			#expect(WMFSettingsDataController.shared.immersiveModeEnabled() == false)
			#expect(WMFAppEnvironment.current.isImmersiveModeEnabled == false)
			let reopenedDisabledViewModel = await makeViewModel()
			#expect(reopenedDisabledViewModel.isImmersiveModeEnabled == false)
		}
	}

	/// The Objective-C construction path must read the preference before its sections are built.
	@Test
	func synchronousInitializerReadsTheSavedPreference() async throws {
		try await withConfiguredEnvironment {
			#expect(WMFSettingsDataController.shared.setImmersiveModeEnabled(true))
			let viewModel = WMFSettingsViewModel.__createSynchronously(
				localizedStrings: localizedStrings,
				username: nil,
				tempUsername: nil,
				isTempAccount: false,
				primaryLanguage: "English",
				readingPreferenceTheme: "Light",
				coordinatorDelegate: nil,
				dataController: WMFSettingsDataController(yirDataController: nil, donationDataController: nil)
			)

			#expect(viewModel.isImmersiveModeEnabled)
			#expect(viewModel.sections.isEmpty)
			await viewModel.refreshSections()
			#expect(try immersiveModeBinding(in: viewModel).wrappedValue)
		}
	}

	/// A failed write must leave the switch, stored setting, and current presentation in agreement.
	@Test(arguments: [false, true])
	func failedSavePreservesThePreviousSetting(initialValue: Bool) async throws {
		try await withConfiguredEnvironment {
			#expect(WMFSettingsDataController.shared.setImmersiveModeEnabled(initialValue))
			WMFAppEnvironment.current.set(isImmersiveModeEnabled: initialValue)
			let viewModel = await makeViewModel()
			let binding = try immersiveModeBinding(in: viewModel)
			let store = try #require(WMFDataEnvironment.current.userDefaultsStore)
			WMFDataEnvironment.current.userDefaultsStore = FailingSaveStore(readStore: store)

			binding.wrappedValue = !initialValue

			#expect(binding.wrappedValue == initialValue)
			#expect(viewModel.isImmersiveModeEnabled == initialValue)
			#expect(WMFSettingsDataController.shared.immersiveModeEnabled() == initialValue)
			#expect(WMFAppEnvironment.current.isImmersiveModeEnabled == initialValue)
		}
	}

	/// A fresh application environment must restore the preference without opening settings first.
	@Test(arguments: [false, true])
	func newEnvironmentReadsTheSavedPreference(savedValue: Bool) async throws {
		try await withConfiguredEnvironment {
			#expect(WMFSettingsDataController.shared.setImmersiveModeEnabled(savedValue))

			#expect(WMFAppEnvironment().isImmersiveModeEnabled == savedValue)
		}
	}

	/// Existing screens and subsequently opened screens must both follow the current switch value.
	@Test
	func controllersHideAndRestoreTheirStatusBars() async throws {
		try await withConfiguredEnvironment {
			let viewModel = await makeViewModel()
			let binding = try immersiveModeBinding(in: viewModel)
			let existingControllers = makeBaseControllers()
			let originalPreferences = existingControllers.map(\.prefersStatusBarHidden)
			#expect(originalPreferences.allSatisfy { $0 == false })

			binding.wrappedValue = true

			#expect(existingControllers.allSatisfy(\.prefersStatusBarHidden))
			let newControllers = makeBaseControllers()
			#expect(newControllers.allSatisfy(\.prefersStatusBarHidden))

			binding.wrappedValue = false

			#expect(existingControllers.map(\.prefersStatusBarHidden) == originalPreferences)
			#expect(newControllers.map(\.prefersStatusBarHidden) == originalPreferences)
		}
	}

	/// Immersive mode must take precedence over an embedded screen that requests a visible status bar.
	@Test
	func navigationControllerOverridesTheChildOnlyWhileEnabled() async throws {
		try await withConfiguredEnvironment {
			let child = VisibleStatusBarController()
			let navigationController = WMFComponentNavigationController(rootViewController: child, modalPresentationStyle: .fullScreen)
			let defaultChild = navigationController.childForStatusBarHidden
			let defaultPreference = navigationController.prefersStatusBarHidden

			WMFAppEnvironment.current.set(isImmersiveModeEnabled: true)

			#expect(child.prefersStatusBarHidden == false)
			#expect(navigationController.prefersStatusBarHidden)
			#expect(navigationController.childForStatusBarHidden == nil)

			WMFAppEnvironment.current.set(isImmersiveModeEnabled: false)

			#expect(navigationController.prefersStatusBarHidden == defaultPreference)
			#expect(navigationController.childForStatusBarHidden === defaultChild)
		}
	}

	/// Acquires the shared data fixture lease and restores app presentation even after a thrown assertion.
	private func withConfiguredEnvironment(_ operation: () async throws -> Void) async throws {
		try await fixture.withConfiguredEnvironment(configure: {
			WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
			WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
			WMFDataEnvironment.current.coreDataStore = nil
		}) {
			let previousValue = WMFAppEnvironment.current.isImmersiveModeEnabled
			defer { WMFAppEnvironment.current.set(isImmersiveModeEnabled: previousValue) }
			WMFAppEnvironment.current.set(isImmersiveModeEnabled: false)
			try await operation()
		}
	}

	/// Builds the settings screen without unrelated donation or year-in-review dependencies.
	private func makeViewModel() async -> WMFSettingsViewModel {
		await WMFSettingsViewModel(
			localizedStrings: localizedStrings,
			username: nil,
			tempUsername: nil,
			isTempAccount: false,
			primaryLanguage: "English",
			readingPreferenceTheme: "Light",
			dataController: WMFSettingsDataController(yirDataController: nil, donationDataController: nil)
		)
	}

	/// Finds the user-facing row by the same stable identifier used in UI automation.
	private func immersiveModeBinding(in viewModel: WMFSettingsViewModel) throws -> Binding<Bool> {
		let item = try #require(viewModel.sections.flatMap(\.items).first { $0.accessibilityIdentifier == AccessibilityIdentifiers.Settings.immersiveModeSwitch })
		let binding: Binding<Bool>?
		if case let .toggle(value) = item.accessory {
			binding = value
		} else {
			binding = nil
		}
		return try #require(binding)
	}

	/// Covers each shared controller family used by UIKit and SwiftUI feature screens.
	private func makeBaseControllers() -> [UIViewController] {
		[
			WMFComponentViewController(),
			WMFComponentHostingController(rootView: EmptyView()),
			WMFComponentNavigationController(rootViewController: UIViewController(), modalPresentationStyle: .fullScreen)
		]
	}

	private var localizedStrings: WMFSettingsViewModel.LocalizedStrings {
		WMFSettingsViewModel.LocalizedStrings(
			settingTitle: "Settings",
			doneButtonTitle: "Done",
			cancelButtonTitle: "Cancel",
			accountTitle: "Account",
			logInTitle: "Log in",
			myLanguagesTitle: "Languages",
			searchTitle: "Search",
			exploreFeedTitle: "Explore feed",
			homeFeedTitle: "Home feed",
			onTitle: "On",
			offTitle: "Off",
			yirTitle: "Year in review",
			pushNotificationsTitle: "Notifications",
			readingpreferences: "Reading preferences",
			articleSyncing: "Article storage",
			databasePopulation: "Database population",
			clearCacheTitle: "Clear cache",
			privacyHeader: "Privacy",
			privacyPolicyTitle: "Privacy policy",
			termsOfUseTitle: "Terms of use",
			rateTheAppTitle: "Rate the app",
			helpTitle: "Help",
			aboutTitle: "About",
			safetyTitle: "Safety"
		)
	}
}

/// Keeps previously stored values readable while simulating a persistence failure.
private struct FailingSaveStore: WMFKeyValueStore {
	let readStore: WMFKeyValueStore

	private enum Failure: Error {
		case save
	}

	func load<T: Codable>(key: String...) throws -> T? {
		try readStore.load(key: key.joined(separator: "."))
	}

	func save<T: Codable>(key: String..., value: T) throws {
		throw Failure.save
	}

	func remove(key: String...) throws {
		try readStore.remove(key: key.joined(separator: "."))
	}

	func keys(inDirectory directory: String) throws -> [String] {
		try readStore.keys(inDirectory: directory)
	}
}

/// Models a legacy screen whose own status-bar preference must not defeat immersive mode.
@MainActor
private final class VisibleStatusBarController: UIViewController {
	override var prefersStatusBarHidden: Bool { false }
}
