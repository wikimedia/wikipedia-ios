import UIKit

public protocol WMFSmallMenuButtonDelegate: AnyObject {
    func wmfMenuButton(_ sender: WMFSmallMenuButton, didTapMenuItem item: WMFSmallMenuButton.MenuItem)
    func wmfMenuButtonDidTap(_ sender: WMFSmallMenuButton)
    func wmfSwiftUIMenuButtonUserDidTap(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?)
    func wmfSwiftUIMenuButtonUserDidTapAccessibility(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?)
}

public extension WMFSmallMenuButtonDelegate {
	func wmfMenuButton(_ sender: WMFSmallMenuButton, didTapMenuItem item: WMFSmallMenuButton.MenuItem) {}
	func wmfMenuButtonDidTap(_ sender: WMFSmallMenuButton) {}
	func wmfSwiftUIMenuButtonUserDidTap(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?) {}
    func wmfSwiftUIMenuButtonUserDidTapAccessibility(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?) {}
}
