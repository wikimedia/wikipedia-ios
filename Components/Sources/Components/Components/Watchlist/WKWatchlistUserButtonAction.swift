import Foundation

/// Action that user has tapped in the menu button
public enum WKWatchlistUserButtonAction {
	case userPage
	case userTalkPage
	case userContributions
	case thank(revisionID: UInt)
}
