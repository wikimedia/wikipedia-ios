import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

/// Covers the opt-in preference, persistence, and safe fallbacks when storage is unavailable.
@Suite(.serialized)
final class WMFSettingsDataControllerImmersiveModeTests {

	private let fixture = WMFDataTestFixture()

	/// A fresh installation keeps the system status bar visible.
	@Test
	func immersiveModeIsDisabledInitially() async {
		await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
			#expect(makeController().immersiveModeEnabled() == false)
		}
	}

	/// Both directions of the toggle remain visible to another controller using the same store.
	@Test
	func togglingImmersiveModePersistsAcrossControllers() async throws {
		try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
			let controller = makeController()
			#expect(controller.setImmersiveModeEnabled(true))
			#expect(controller.immersiveModeEnabled())
			#expect(makeController().immersiveModeEnabled())

			let savedValue: Bool? = try WMFDataEnvironment.current.userDefaultsStore?.load(key: "immersive-mode-enabled")
			#expect(savedValue == true)

			#expect(controller.setImmersiveModeEnabled(false))
			#expect(controller.immersiveModeEnabled() == false)
			#expect(makeController().immersiveModeEnabled() == false)
		}
	}

	/// Recreating the defaults store preserves the preference without relying on a controller cache.
	@Test
	func immersiveModePersistsAcrossUserDefaultsStores() async throws {
		try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
			try withIsolatedUserDefaults { defaults, suiteName in
				WMFDataEnvironment.current.userDefaultsStore = WMFUserDefaultsStore(defaults: defaults)
				#expect(makeController().immersiveModeEnabled() == false)
				#expect(makeController().setImmersiveModeEnabled(true))

				let reopenedDefaults = try #require(UserDefaults(suiteName: suiteName))
				WMFDataEnvironment.current.userDefaultsStore = WMFUserDefaultsStore(defaults: reopenedDefaults)
				#expect(makeController().immersiveModeEnabled())
				#expect(makeController().setImmersiveModeEnabled(false))

				WMFDataEnvironment.current.userDefaultsStore = WMFUserDefaultsStore(defaults: defaults)
				#expect(makeController().immersiveModeEnabled() == false)
			}
		}
	}

	/// Invalid JSON and a valid JSON value of the wrong type cannot enable immersive mode.
	@Test(arguments: ["not-json", "\"enabled\""])
	func unreadablePreferenceDefaultsToDisabled(serializedValue: String) async throws {
		try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
			try withIsolatedUserDefaults { defaults, _ in
				defaults.set(Data(serializedValue.utf8), forKey: "immersive-mode-enabled")
				WMFDataEnvironment.current.userDefaultsStore = WMFUserDefaultsStore(defaults: defaults)
				#expect(makeController().immersiveModeEnabled() == false)
			}
		}
	}

	/// A missing store uses the default and reports that neither toggle value could be saved.
	@Test
	func missingStoreDefaultsToDisabledAndRejectsWrites() async {
		await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
			WMFDataEnvironment.current.userDefaultsStore = nil
			let controller = makeController()
			#expect(controller.immersiveModeEnabled() == false)
			#expect(controller.setImmersiveModeEnabled(true) == false)
			#expect(controller.setImmersiveModeEnabled(false) == false)
			#expect(controller.immersiveModeEnabled() == false)
		}
	}

	/// Failed writes report failure and leave the last successfully stored value intact.
	@Test(arguments: [false, true])
	func failedWritePreservesStoredPreference(storedValue: Bool) async {
		await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
			WMFDataEnvironment.current.userDefaultsStore = ReadOnlyStore(storedValue: storedValue)
			let controller = makeController()
			#expect(controller.immersiveModeEnabled() == storedValue)
			#expect(controller.setImmersiveModeEnabled(!storedValue) == false)
			#expect(controller.immersiveModeEnabled() == storedValue)
			#expect(makeController().immersiveModeEnabled() == storedValue)
		}
	}

	/// Supplies a fresh mock under the fixture's global environment lease.
	private func configureEnvironment() async {
		WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
	}

	/// Avoids initializing unrelated donation and year-in-review dependencies.
	private func makeController() -> WMFSettingsDataController {
		WMFSettingsDataController(yirDataController: nil, donationDataController: nil)
	}

	/// Removes this test's unique defaults domain even when an assertion throws.
	private func withIsolatedUserDefaults(_ operation: (UserDefaults, String) throws -> Void) throws {
		let suiteName = "WMFSettingsDataControllerImmersiveModeTests-\(UUID().uuidString)"
		let defaults = try #require(UserDefaults(suiteName: suiteName))
		defer { defaults.removePersistentDomain(forName: suiteName) }
		try operation(defaults, suiteName)
	}

	/// Immutable storage that serves an existing preference but rejects every mutation.
	private struct ReadOnlyStore: WMFKeyValueStore, Sendable {
		let storedValue: Bool

		private enum StoreError: Error {
			case readOnly
		}

		func load<T: Codable>(key: String...) throws -> T? {
			guard key == ["immersive-mode-enabled"] else { return nil }
			return storedValue as? T
		}

		func save<T: Codable>(key: String..., value: T) throws {
			throw StoreError.readOnly
		}

		func remove(key: String...) throws {
			throw StoreError.readOnly
		}

		func keys(inDirectory directory: String) throws -> [String] {
			[]
		}
	}
}
