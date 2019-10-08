import UIKit

@objc(WMFAppSearchBarButtonItem)
class AppSearchBarButtonItem: UIBarButtonItem {
    @objc static var newAppSearchBarButtonItem: AppSearchBarButtonItem {
        let button = AppSearchBarButtonItem(image: UIImage(named: "search"), style: .plain, target: self, action: #selector(makeAppSearchViewActivityActive))
        button.accessibilityLabel = WMFLocalizedString("search-button-accessibility-label", value: "Search Wikipedia", comment: "Accessibility label for a button that opens a search box to search Wikipedia.")
        return button
    }
    
    @objc static func makeAppSearchViewActivityActive() {
        NSUserActivity.wmf_navigate(to: NSUserActivity.wmf_searchView())
    }
}
