import Foundation

@objc(WMFLogoutCoordinatorDelegate)
protocol LogoutCoordinatorDelegate: AnyObject {
    func didTapLogout()
}

