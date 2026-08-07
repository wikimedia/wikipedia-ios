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

    static let hideModule = WMFLocalizedString("home-menu-hide-module", value: "Hide module", comment: "Menu action to hide the whole Home feed module that contains this card.")
}
