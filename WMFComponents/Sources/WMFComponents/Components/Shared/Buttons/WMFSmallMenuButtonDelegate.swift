import UIKit

public protocol WMFSmallMenuButtonDelegate: AnyObject {
    func WMFMenuButton(_ sender: WMFSmallMenuButton, didTapMenuItem item: WMFSmallMenuButton.MenuItem)
    func WMFMenuButtonDidTap(_ sender: WMFSmallMenuButton)

	func WMFSwiftUIMenuButtonUserDidTap(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?)
    func WMFSwiftUIMenuButtonUserDidTapAccessibility(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?)
}

public extension WMFSmallMenuButtonDelegate {
	func WMFMenuButton(_ sender: WMFSmallMenuButton, didTapMenuItem item: WMFSmallMenuButton.MenuItem) {}
	func WMFMenuButtonDidTap(_ sender: WMFSmallMenuButton) {}
	func WMFSwiftUIMenuButtonUserDidTap(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?) {}
    func WMFSwiftUIMenuButtonUserDidTapAccessibility(configuration: WMFSmallMenuButton.Configuration, item: WMFSmallMenuButton.MenuItem?) {}
}
