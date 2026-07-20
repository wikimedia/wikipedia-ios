import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

@Suite
struct WMFHomeDataControllerSettingsTests {

    private func makeController() -> WMFHomeDataController {
        return WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
    }

    // MARK: - Defaults

    @Test
    func communityModulesDefaultToOn() {
        let controller = makeController()
        #expect(controller.communityFeaturedArticleIsOn() == true)
        #expect(controller.communityTopReadIsOn() == true)
        #expect(controller.communityInTheNewsIsOn() == true)
        #expect(controller.communityOnThisDayIsOn() == true)
        #expect(controller.communityPictureOfTheDayIsOn() == true)
    }

    @Test
    func forYouModulesDefaultToOn() {
        let controller = makeController()
        #expect(controller.forYouBasedOnInterestsIsOn() == true)
        #expect(controller.forYouBecauseYouReadIsOn() == true)
        #expect(controller.forYouContinueReadingIsOn() == true)
    }

    @Test
    func seeFirstContentDefaultsToCommunity() {
        let controller = makeController()
        #expect(controller.seeFirstContent() == .community)
    }

    @Test
    func seeFirstContentPersistsChanges() {
        let controller = makeController()
        controller.setSeeFirstContent(.personalized)
        #expect(controller.seeFirstContent() == .personalized)
        controller.setSeeFirstContent(.community)
        #expect(controller.seeFirstContent() == .community)
    }

    // MARK: - Persistence

    @Test
    func communityModulesPersistChanges() {
        let controller = makeController()

        controller.setCommunityFeaturedArticleIsOn(false)
        controller.setCommunityTopReadIsOn(false)
        controller.setCommunityInTheNewsIsOn(false)
        controller.setCommunityOnThisDayIsOn(false)
        controller.setCommunityPictureOfTheDayIsOn(false)

        #expect(controller.communityFeaturedArticleIsOn() == false)
        #expect(controller.communityTopReadIsOn() == false)
        #expect(controller.communityInTheNewsIsOn() == false)
        #expect(controller.communityOnThisDayIsOn() == false)
        #expect(controller.communityPictureOfTheDayIsOn() == false)

        // Flip one back on to confirm round-trip both directions.
        controller.setCommunityTopReadIsOn(true)
        #expect(controller.communityTopReadIsOn() == true)
    }

    @Test
    func forYouModulesPersistChanges() {
        let controller = makeController()

        controller.setForYouBasedOnInterestsIsOn(false)
        controller.setForYouBecauseYouReadIsOn(false)
        controller.setForYouContinueReadingIsOn(false)

        #expect(controller.forYouBasedOnInterestsIsOn() == false)
        #expect(controller.forYouBecauseYouReadIsOn() == false)
        #expect(controller.forYouContinueReadingIsOn() == false)

        controller.setForYouContinueReadingIsOn(true)
        #expect(controller.forYouContinueReadingIsOn() == true)
    }

    // MARK: - Selected Language

    @Test
    func selectedLanguageDefaultsToNil() {
        let controller = makeController()
        #expect(controller.selectedLanguage() == nil)
    }

    @Test
    func selectedLanguagePersistsChanges() {
        let controller = makeController()

        controller.setSelectedLanguage(WMFLanguage(languageCode: "es", languageVariantCode: nil))
        #expect(controller.selectedLanguage() == WMFLanguage(languageCode: "es", languageVariantCode: nil))

        controller.setSelectedLanguage(WMFLanguage(languageCode: "zh", languageVariantCode: "zh-hant"))
        #expect(controller.selectedLanguage() == WMFLanguage(languageCode: "zh", languageVariantCode: "zh-hant"))
    }

    // MARK: - Interest Topics

    @Test
    func interestTopicsDefaultToEmpty() {
        let controller = makeController()
        #expect(controller.interestTopics() == [])
    }

    @Test
    func interestTopicsPersistChanges() {
        let controller = makeController()

        controller.setInterestTopics([.architecture, .music, .stem])
        #expect(controller.interestTopics() == [.architecture, .music, .stem])
    }

    @Test
    func interestTopicsCanBeCleared() {
        let controller = makeController()

        controller.setInterestTopics([.architecture, .music])
        controller.setInterestTopics([])
        #expect(controller.interestTopics() == [])
    }

    @Test
    func separateControllersShareInterestTopics() {
        let store = WMFMockKeyValueStore()
        let writer = WMFHomeDataController(userDefaultsStore: store)
        writer.setInterestTopics([.biology, .films])

        let reader = WMFHomeDataController(userDefaultsStore: store)
        #expect(reader.interestTopics() == [.biology, .films])
    }

    // MARK: - Independence

    @Test
    func togglingOneModuleDoesNotAffectOthers() {
        let controller = makeController()

        controller.setCommunityFeaturedArticleIsOn(false)

        // Only the featured article toggle should have changed.
        #expect(controller.communityFeaturedArticleIsOn() == false)
        #expect(controller.communityTopReadIsOn() == true)
        #expect(controller.communityInTheNewsIsOn() == true)
        #expect(controller.communityOnThisDayIsOn() == true)
        #expect(controller.communityPictureOfTheDayIsOn() == true)

        // For You toggles are stored under separate keys and remain on.
        #expect(controller.forYouBasedOnInterestsIsOn() == true)
        #expect(controller.forYouBecauseYouReadIsOn() == true)
        #expect(controller.forYouContinueReadingIsOn() == true)
    }

    @Test
    func separateControllersShareTheSameStore() {
        let store = WMFMockKeyValueStore()
        let writer = WMFHomeDataController(userDefaultsStore: store)
        writer.setForYouBecauseYouReadIsOn(false)

        let reader = WMFHomeDataController(userDefaultsStore: store)
        #expect(reader.forYouBecauseYouReadIsOn() == false)
    }

    // MARK: - Hidden Cards

    @Test
    func hiddenCardKeysDefaultToEmpty() {
        let controller = makeController()
        #expect(controller.hiddenCardKeys() == [])
    }

    @Test
    func hideCardAppendsKey() {
        let controller = makeController()
        controller.hideCard(key: "featured_article_Octopus")
        #expect(controller.hiddenCardKeys() == ["featured_article_Octopus"])
    }

    @Test
    func hideCardIgnoresDuplicates() {
        let controller = makeController()
        controller.hideCard(key: "featured_article_Octopus")
        controller.hideCard(key: "featured_article_Octopus")
        #expect(controller.hiddenCardKeys().count == 1)
    }

    @Test
    func isCardHiddenReturnsTrueAfterHide() {
        let controller = makeController()
        controller.hideCard(key: "top_read_2025-06-26_enwiki")
        #expect(controller.isCardHidden(key: "top_read_2025-06-26_enwiki") == true)
    }

    @Test
    func isCardHiddenReturnsFalseForUnhiddenKey() {
        let controller = makeController()
        #expect(controller.isCardHidden(key: "top_read_2025-06-26_enwiki") == false)
    }

    @Test
    func hideCardEnforcesFIFOCapOf100() {
        let controller = makeController()
        for i in 0..<105 {
            controller.hideCard(key: "card_\(i)")
        }
        let keys = controller.hiddenCardKeys()
        #expect(keys.count == 100)
        // Oldest keys (0–4) should have been evicted; newest should remain.
        #expect(keys.contains("card_4") == false)
        #expect(keys.contains("card_5") == true)
        #expect(keys.contains("card_104") == true)
    }

    @Test
    func hiddenCardKeysSharedAcrossControllers() {
        let store = WMFMockKeyValueStore()
        let writer = WMFHomeDataController(userDefaultsStore: store)
        writer.hideCard(key: "for_you_enwiki_Octopus")

        let reader = WMFHomeDataController(userDefaultsStore: store)
        #expect(reader.isCardHidden(key: "for_you_enwiki_Octopus") == true)
    }

    @Test
    func hiddenCardKeysPreservesInsertionOrder() {
        let controller = makeController()
        controller.hideCard(key: "card_a")
        controller.hideCard(key: "card_b")
        controller.hideCard(key: "card_c")
        #expect(controller.hiddenCardKeys() == ["card_a", "card_b", "card_c"])
    }
}
