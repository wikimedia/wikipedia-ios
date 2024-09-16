import Foundation

// I'm using a traditional delegate pattern to navigate between packages
public protocol ProfileCoordinatorDelegate: AnyObject {
    func handleProfileAction(_ action: ProfileAction)
}


// Actions
// Actions help us create other routes using the delegate
public enum ProfileAction {
    case showNotifications
    case showSettings
    case showDonate
    // Add other actions
}
