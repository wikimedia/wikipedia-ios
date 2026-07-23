import XCTest
import SwiftUI
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

/// Extracts the `Binding<Bool>` from every `.toggle` row in the given sections, in order.
@MainActor
private func toggleBindings(_ sections: [SettingsSection]) -> [Binding<Bool>] {
    sections.flatMap { $0.items }.compactMap { item in
        if case let .toggle(binding) = item.accessory {
            return binding
        }
        return nil
    }
}

@MainActor
final class WMFHomeFeedSettingsViewModelTests: XCTestCase {

    func testCommunitySectionHiddenWithoutHomePhase2() {
        let vm = WMFHomeFeedSettingsViewModel(showCommunitySettings: false)
        XCTAssertEqual(vm.sections.count, 1)
        // Only the For You section remains: Modules + What's Driving rows.
        XCTAssertEqual(vm.sections[0].items.count, 2)
    }

    func testCommunitySectionShownWithHomePhase2() {
        let vm = WMFHomeFeedSettingsViewModel(showCommunitySettings: true)
        XCTAssertEqual(vm.sections.count, 2)
        // Community section leads with its single Modules row.
        XCTAssertEqual(vm.sections[0].items.count, 1)
        XCTAssertEqual(vm.sections[1].items.count, 2)
    }
}

@MainActor
final class WMFHomeFeedCommunitySettingsViewModelTests: XCTestCase {

    private func makeController() -> WMFHomeDataController {
        WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
    }

    func testTogglesDefaultToOn() {
        let vm = WMFHomeFeedCommunitySettingsViewModel(homeDataController: makeController())
        XCTAssertTrue(vm.featuredArticleIsOn)
        XCTAssertTrue(vm.topReadIsOn)
        XCTAssertTrue(vm.inTheNewsIsOn)
        XCTAssertTrue(vm.onThisDayIsOn)
        XCTAssertTrue(vm.pictureOfTheDayIsOn)
    }

    func testTogglingBindingPersistsThroughDataController() {
        let controller = makeController()
        let vm = WMFHomeFeedCommunitySettingsViewModel(homeDataController: controller)

        let bindings = toggleBindings(vm.sections)
        XCTAssertEqual(bindings.count, 5)

        // First toggle is Featured article. Flipping it must persist via the data controller.
        bindings[0].wrappedValue = false

        XCTAssertFalse(controller.communityFeaturedArticleIsOn())

        // A fresh view model backed by the same controller reads the persisted value.
        let vm2 = WMFHomeFeedCommunitySettingsViewModel(homeDataController: controller)
        XCTAssertFalse(vm2.featuredArticleIsOn)
        XCTAssertTrue(vm2.topReadIsOn)
    }

    func testReadsPersistedValuesOnInit() {
        let controller = makeController()
        controller.setCommunityTopReadIsOn(false)

        let vm = WMFHomeFeedCommunitySettingsViewModel(homeDataController: controller)
        XCTAssertFalse(vm.topReadIsOn)
        XCTAssertTrue(vm.featuredArticleIsOn)
    }
}

@MainActor
final class WMFHomeFeedForYouSettingsViewModelTests: XCTestCase {

    private func makeController() -> WMFHomeDataController {
        WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
    }

    func testTogglesDefaultToOn() {
        let vm = WMFHomeFeedForYouSettingsViewModel(homeDataController: makeController())
        XCTAssertTrue(vm.basedOnYourInterestsIsOn)
        XCTAssertTrue(vm.becauseYouReadIsOn)
        XCTAssertTrue(vm.continueReadingIsOn)
    }

    func testTogglingBindingPersistsThroughDataController() {
        let controller = makeController()
        let vm = WMFHomeFeedForYouSettingsViewModel(homeDataController: controller)

        let bindings = toggleBindings(vm.sections)
        // Three toggles (the "What's driving your feed" link row has no toggle).
        XCTAssertEqual(bindings.count, 3)

        // First toggle is Based on your interests. Flipping it must persist via the data controller.
        bindings[0].wrappedValue = false

        XCTAssertFalse(controller.forYouBasedOnInterestsIsOn())

        // A fresh view model backed by the same controller reads the persisted value.
        let vm2 = WMFHomeFeedForYouSettingsViewModel(homeDataController: controller)
        XCTAssertFalse(vm2.basedOnYourInterestsIsOn)
        XCTAssertTrue(vm2.becauseYouReadIsOn)
        XCTAssertTrue(vm2.continueReadingIsOn)
    }

    func testReadsPersistedValuesOnInit() {
        let controller = makeController()
        controller.setForYouContinueReadingIsOn(false)

        let vm = WMFHomeFeedForYouSettingsViewModel(homeDataController: controller)
        XCTAssertFalse(vm.continueReadingIsOn)
        XCTAssertTrue(vm.basedOnYourInterestsIsOn)
    }
}
