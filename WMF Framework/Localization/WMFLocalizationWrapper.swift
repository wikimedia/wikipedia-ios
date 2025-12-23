import Foundation
import WMFNativeLocalizations

@objc public final class WMFLocalizationWrapper: NSObject {

    @objc public static func wmf_NewLocalizedStringWithDefaultValue(
        _ key: String,
        wikipediaLanguageCode: String? = nil,
        bundle: Bundle? = nil,
        value: String,
        comment: String
    ) -> String {
        WMFLocalizedString(key, languageCode: wikipediaLanguageCode, bundle: bundle, value: value, comment: comment)
    }
    
    @objc public static let wmf_localizationBundle = Bundle.wmf_localizationBundle
}

@objc public final class WMFCommonStringsWrapper: NSObject {

    @objc public static let continueReadingTitle = CommonStrings.continueReadingTitle
    @objc public static let relatedPagesTitle = CommonStrings.relatedPagesTitle
    @objc public static let pictureOfTheDayTitle = CommonStrings.pictureOfTheDayTitle
    @objc public static let featuredArticleTitle = CommonStrings.featuredArticleTitle
    @objc public static let onThisDayTitle = CommonStrings.onThisDayTitle
    @objc public static let suggestedEditsTitle = CommonStrings.suggestedEditsTitle
    @objc public static let fromWikipedia = CommonStrings.fromWikipedia
    @objc public static let defaultFromWikipedia = CommonStrings.defaultFromWikipedia
    @objc public static let nearbyFooterTitle = CommonStrings.nearbyFooterTitle
    @objc public static let randomizerTitle = CommonStrings.randomizerTitle
    @objc public static let privacyPolicyURLString = CommonStrings.privacyPolicyURLString
    @objc public static let confirmDeletionSubtitle = CommonStrings.confirmDeletionSubtitle
    @objc public static let deleteActionTitle = CommonStrings.deleteActionTitle
    @objc public static let cancelActionTitle = CommonStrings.cancelActionTitle
    @objc public static let confirmedDeletion = CommonStrings.confirmedDeletion
    @objc public static let confirmDeletionTitle = CommonStrings.confirmDeletionTitle
    @objc public static let account = CommonStrings.account
    @objc public static let donateTitle = CommonStrings.donateTitle
    @objc public static let myLanguages = CommonStrings.myLanguages
    @objc public static let searchTitle = CommonStrings.searchTitle
    @objc public static let tabsTitle = CommonStrings.tabsTitle
    @objc public static let exploreFeedTitle = CommonStrings.exploreFeedTitle
    @objc public static let offGenericTitle = CommonStrings.offGenericTitle
    @objc public static let onGenericTitle = CommonStrings.onGenericTitle
    @objc public static let pushNotifications = CommonStrings.pushNotifications
    @objc public static let yirTitle = CommonStrings.yirTitle
    @objc public static let readingPreferences = CommonStrings.readingPreferences
    @objc public static let settingsStorageAndSyncing = CommonStrings.settingsStorageAndSyncing
    @objc public static let deleteDonationHistory = CommonStrings.deleteDonationHistory
    @objc public static let tempAccount = CommonStrings.tempAccount
    @objc public static let wikipediaLanguages = CommonStrings.wikipediaLanguages
    @objc public static let customizeExploreFeedTitle = CommonStrings.customizeExploreFeedTitle
    @objc public static let okTitle = CommonStrings.okTitle
    @objc public static let doneTitle = CommonStrings.doneTitle
    @objc public static let closeButtonAccessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
    @objc public static let exploreTabTitle = CommonStrings.exploreTabTitle
    @objc public static let savedTabTitle = CommonStrings.savedTabTitle
    @objc public static let historyTabTitle = CommonStrings.historyTabTitle
    @objc public static let activityTitle = CommonStrings.activityTitle
    @objc public static let settingsTitle = CommonStrings.settingsTitle
    @objc public static let placesTabTitle = CommonStrings.placesTabTitle
    @objc public static let noInternetConnection = CommonStrings.noInternetConnection
    @objc public static let createNewListTitle = CommonStrings.createNewListTitle
    @objc public static let emptyNoHistoryTitle = CommonStrings.emptyNoHistoryTitle
    @objc public static let emptyNoHistorySubtitle = CommonStrings.emptyNoHistorySubtitle
    @objc public static let diffErrorTitle = CommonStrings.diffErrorTitle
    @objc public static let plainWikipediaName = CommonStrings.plainWikipediaName
    @objc public static let logIn = CommonStrings.logIn
}
