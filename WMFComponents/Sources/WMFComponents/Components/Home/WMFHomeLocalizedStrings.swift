import Foundation
import WMFNativeLocalizations

/// Strings shared by both Home feed segments.
///
/// The For You cards and the Community cards offer the same two menu actions, so they must resolve
/// to the same translation. Defining them once keeps a single key per string, rather than sending
/// translators the same English twice under two names.
enum WMFHomeLocalizedStrings {

    static var hideCard: String {
        CommonStrings.hideCardTitle
    }

    /// Spoken label for the three-dot button
    static let moreOptions = WMFLocalizedString("home-card-more-options-accessibility-label", value: "More options", comment: "Accessibility label for the three dot button on a Home feed card, which opens a menu of actions for that card.")

    static let hideModule = WMFLocalizedString("home-menu-hide-module", value: "Hide module", comment: "Menu action to hide the whole Home feed module that contains this card.")

    /// VoiceOver equivalent of swiping up on a For You card. Swiping left and right already moves
    /// through the cards of one module, so moving between modules needs an action of its own.
    static let nextModule = WMFLocalizedString("home-for-you-next-module-accessibility-action", value: "Next module", comment: "Accessibility action on a For You card that moves to the next module in the feed. It is the VoiceOver equivalent of swiping up.")

    static let previousModule = WMFLocalizedString("home-for-you-previous-module-accessibility-action", value: "Previous module", comment: "Accessibility action on a For You card that moves to the previous module in the feed. It is the VoiceOver equivalent of swiping down.")

    /// Spoken after a card's title, so someone swiping through a module knows where they are in it.
    /// The page dots carry this for sighted users, and they are hidden from VoiceOver.
    static func cardPosition(_ position: Int, of total: Int) -> String {
        String.localizedStringWithFormat(cardPositionFormat, position, total)
    }

    private static let cardPositionFormat = WMFLocalizedString("home-for-you-card-position-accessibility-value", value: "%1$d of %2$d", comment: "Accessibility value spoken for a For You card, giving its place in the module. %1$d is replaced with the card's position and %2$d with the number of cards in the module, e.g. \"2 of 4\".")
}
