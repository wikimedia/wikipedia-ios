import UIKit

public protocol WKSmallMenuButtonDelegate: AnyObject {
    func wkMenuButton(_ sender: WKSmallMenuButton, didTapMenuItem item: WKSmallMenuButton.MenuItem)
    func wkMenuButtonDidTap(_ sender: WKSmallMenuButton)

	func wkSwiftUIMenuButtonUserDidTap(configuration: WKSmallMenuButton.Configuration, item: WKSmallMenuButton.MenuItem?)
    func wkSwiftUIMenuButtonUserDidTapAccessibility(configuration: WKSmallMenuButton.Configuration, item: WKSmallMenuButton.MenuItem?)
}

public extension WKSmallMenuButtonDelegate {
	func wkMenuButton(_ sender: WKSmallMenuButton, didTapMenuItem item: WKSmallMenuButton.MenuItem) {}
	func wkMenuButtonDidTap(_ sender: WKSmallMenuButton) {}
	func wkSwiftUIMenuButtonUserDidTap(configuration: WKSmallMenuButton.Configuration, item: WKSmallMenuButton.MenuItem?) {}
    func wkSwiftUIMenuButtonUserDidTapAccessibility(configuration: WKSmallMenuButton.Configuration, item: WKSmallMenuButton.MenuItem?) {}
}
