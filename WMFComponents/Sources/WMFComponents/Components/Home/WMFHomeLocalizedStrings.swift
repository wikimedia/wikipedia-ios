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
}
